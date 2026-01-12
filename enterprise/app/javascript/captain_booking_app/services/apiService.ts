
import { ApiPostPayload, N8nApiResponse } from '../types.ts';

// Endpoints now point to Chatwoot Public API (served on same domain or configured BASE_URL)
const API_BASE_URL = '/public/api/v1/captain'; 
const API_ENDPOINT = `${API_BASE_URL}/reservations`; 

interface PaymentStatusResponse {
  status: 'pago' | 'aguardando_pagamento' | string;
}

export const checkPaymentStatus = async (txid: string): Promise<PaymentStatusResponse> => {
  // Using reservation ID (which we need to capture from submission) or txid if indexed
  // For simplicity porting, we assume txid maps to integracao_id or we adjust logic to use ID
  
  // Note: Original app checked TXID against Supabase. 
  // Chatwoot endpoint: GET /public/api/v1/captain/reservations/:identifier
  // We need to pass the RESERVATION ID here, not just TXID, unless we search by TXID.
  // Let's assume we search by integracao_id (which maps to TXID/Reference)
  
  const response = await fetch(`${API_ENDPOINT}/${txid}/status`, {
    method: 'GET',
    headers: { 'Content-Type': 'application/json' },
  });

  if (!response.ok) {
     throw new Error(`Erro ao verificar pagamento: ${response.status}`);
  }
  
  const data = await response.json();
  // Map Chatwoot status to expected frontend status
  // Chatwoot: 'active' (paid), 'pending_payment'
  // Frontend expects: 'pago'
  
  return {
    status: data.payment_status === 'paid' ? 'pago' : 'aguardando_pagamento'
  };
};


export const submitReservation = async (payload: ApiPostPayload): Promise<N8nApiResponse> => {
  const response = await fetch(API_ENDPOINT, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) { 
    let detailedErrorMessage = `Erro HTTP: ${response.status} ${response.statusText}`;
    try {
      const errorData = await response.json();
      if (errorData && errorData.message) { 
        detailedErrorMessage = errorData.message;
      }
    } catch (e) {
        // Ignore if error response is not JSON
    }
    throw new Error(detailedErrorMessage);
  }

  const responseText = await response.text();
  if (!responseText) {
    throw new Error('Resposta do servidor vazia. A API não retornou os dados do Pix necessários.');
  }

  try {
    let successData = JSON.parse(responseText);
    
    // The webhook might return an array with a single object.
    // We check for that and extract the object if necessary.
    if (Array.isArray(successData) && successData.length > 0) {
      successData = successData[0];
    }

    // After potentially unwrapping, validate the final object has the required fields.
    if (successData && successData.pixCopiaECola && successData.pixUrl && successData.txid) {
        return successData as N8nApiResponse;
    } else {
        console.error("Parsed API response is missing required PIX fields:", successData);
        throw new Error('A API retornou uma resposta, mas os dados do Pix estão incompletos ou em formato inesperado.');
    }
  } catch (e) {
    console.error("Failed to parse JSON response:", responseText);
    throw new Error(`Resposta do servidor inválida. Não foi possível processar os dados recebidos.`);
  }
};