import type { PricingData, PricingRow, Brand } from '../types.ts';

const API_BASE_URL = '/public/api/v1/captain';

const fetchMasterData = async () => {
    const response = await fetch(`${API_BASE_URL}/master_data?account_id=1`);
    if (!response.ok) throw new Error('Falha ao carregar dados do servidor.');
    return response.json();
};

const transformToPricingData = (rows: any[]): PricingData => {
  const pricingData: PricingData = {};
  for (const row of rows) {
    if (!pricingData[row.day_range]) {
      pricingData[row.day_range] = {};
    }
    if (!pricingData[row.day_range][row.suite_category]) {
      pricingData[row.day_range][row.suite_category] = {};
    }
    // Rails returns strings for decimals usually, ensure number
    pricingData[row.day_range][row.suite_category][row.duration] = Number(row.price);
  }
  return pricingData;
};

export const pricingService = {
  // Busca os dados de preço de uma marca e formata para a UI
  async getPricingData(brandId: number): Promise<PricingData> {
    const data = await fetchMasterData();
    // Use loose equality or cast both to string to be safe with IDs from JSON
    const rows = data.pricings.filter((p: any) => String(p.captain_brand_id) === String(brandId));
    // Wait, in the migration: t.references :captain_brand
    // So the column is captain_brand_id.
    // But `types.ts` `PricingRow` likely expects `brand_id`.
    
    // Let's create an adapter if needed.
    // For now, assuming p.captain_brand_id is what we get from Rails.
    const adaptedRows = rows.map((r: any) => ({
        ...r,
        suite_category: r.suite_category,
        day_range: r.day_range,
        duration: r.duration,
        price: r.price
    }));

    return transformToPricingData(adaptedRows);
  },

  // Salva (upsert) todos os dados de preço de uma marca
  async savePricingData(brandId: number, data: PricingData): Promise<void> {
    throw new Error("Operação não permitida na interface pública.");
  },

  // Garante que a estrutura de preços exista para uma marca, criando linhas com preço 0 se necessário
  async syncPricingForBrand(brand: Brand): Promise<void> {
    // No-op or throw
    console.log("Sync pricing skipped in public mode");
  }
};
