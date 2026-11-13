'use strict';

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { defineSecret } = require('firebase-functions/params');
const { HttpsError, onCall } = require('firebase-functions/v2/https');

initializeApp();

const db = getFirestore();
const geminiKey = defineSecret('GEMINI_API_KEY');
const maxRequestsPerWindow = 5;
const rateLimitWindowMs = 10 * 60 * 1000;

function boundedString(value, field, maxLength) {
  if (typeof value !== 'string') {
    throw new HttpsError('invalid-argument', `${field} must be text.`);
  }
  const trimmed = value.trim();
  if (!trimmed) {
    throw new HttpsError('invalid-argument', `${field} cannot be empty.`);
  }
  if (trimmed.length > maxLength) {
    throw new HttpsError(
      'invalid-argument',
      `${field} must be ${maxLength} characters or fewer.`,
    );
  }
  return trimmed;
}

async function checkRateLimit(uid) {
  const now = Date.now();
  const windowStart = Math.floor(now / rateLimitWindowMs) * rateLimitWindowMs;
  const ref = db.collection('aiRateLimits').doc(uid);

  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const data = snapshot.data();
    const currentWindow = data?.windowStart?.toMillis?.() ?? 0;
    const count =
      currentWindow === windowStart && Number.isInteger(data?.count)
        ? data.count
        : 0;

    if (count >= maxRequestsPerWindow) {
      throw new HttpsError(
        'resource-exhausted',
        'You have reached the AI request limit. Please try again later.',
      );
    }

    transaction.set(ref, {
      windowStart: Timestamp.fromMillis(windowStart),
      count: count + 1,
    });
  });
}

exports.generateContent = onCall(
  {
    region: 'us-central1',
    secrets: [geminiKey],
    timeoutSeconds: 90,
    maxInstances: 10,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Login required.');
    }
    if (!request.data || typeof request.data !== 'object') {
      throw new HttpsError('invalid-argument', 'AI prompt is required.');
    }

    const system = boundedString(request.data.system, 'System prompt', 3000);
    const user = boundedString(request.data.user, 'User prompt', 12000);
    const profileImport = request.data.profileImport === true;
    const parts = [];
    if (request.data.pdfBase64 !== undefined) {
      if (!profileImport || typeof request.data.pdfBase64 !== 'string') {
        throw new HttpsError('invalid-argument', 'Invalid profile PDF.');
      }
      const pdfBase64 = request.data.pdfBase64;
      if (!/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(pdfBase64)) {
        throw new HttpsError('invalid-argument', 'Invalid profile PDF.');
      }
      const pdf = Buffer.from(pdfBase64, 'base64');
      if (pdf.length === 0 || pdf.length > 4 * 1024 * 1024) {
        throw new HttpsError(
          'invalid-argument',
          'PDF is too large (max 4 MB) or empty.',
        );
      }
      parts.push({
        inlineData: {
          mimeType: 'application/pdf',
          data: pdfBase64,
        },
      });
    }
    parts.push({ text: user });

    await checkRateLimit(request.auth.uid);

    let response;
    try {
      response = await fetch(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': geminiKey.value(),
          },
          body: JSON.stringify({
            systemInstruction: {
              parts: [{ text: system }],
            },
            contents: [
              {
                role: 'user',
                parts,
              },
            ],
            generationConfig: {
              temperature: profileImport ? 0.1 : 0.7,
              maxOutputTokens: profileImport ? 4000 : 700,
              ...(profileImport ? { responseMimeType: 'application/json' } : {}),
            },
          }),
        },
      );
    } catch (_) {
      throw new HttpsError(
        'unavailable',
        'The AI service is temporarily unavailable. Please try again.',
      );
    }

    if (!response.ok) {
      throw new HttpsError(
        'unavailable',
        `AI request failed (${response.status}). Please try again.`,
      );
    }

    let data;
    try {
      data = await response.json();
    } catch (_) {
      throw new HttpsError(
        'internal',
        'The AI service returned an invalid response.',
      );
    }

    const text = data.candidates?.[0]?.content?.parts
      ?.map((part) => part.text)
      .filter((part) => typeof part === 'string')
      .join('\n');
    if (typeof text !== 'string' || !text.trim()) {
      throw new HttpsError(
        'internal',
        'The AI service returned an empty response.',
      );
    }
    return { text: text.trim() };
  },
);
