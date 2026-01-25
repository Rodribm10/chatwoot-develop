
import { Brand, HotelUnit, ExtraItem, PricingData } from '../types.ts';

const API_BASE_URL = '/public/api/v1/captain';

export interface CaptainConfig {
  title: string;
  subtitle: string;
  primary_color: string;
  secondary_color?: string;
  logo_url?: string;
  phone_number?: string;
}

export interface MasterDataResponse {
  app_config: CaptainConfig;
  brands: Brand[];
  // units are nested in brands in the current serializer, but top level master data might return flattened too if needed
  // checking controller: render json: { ... brands: brands.as_json(include: :units) ... }
  pricings: any; // Using any for now or specific PricingData[] type if available
  extras: ExtraItem[];
  suites: any[];
}

let cachedMasterData: MasterDataResponse | null = null;

export const masterDataService = {
  async getMasterData(): Promise<MasterDataResponse> {
    if (cachedMasterData) return cachedMasterData;

    try {
        // Hardcoded account_id=1 for now, similar to other services
        const response = await fetch(`${API_BASE_URL}/master_data?account_id=1`);
        if (!response.ok) throw new Error('Falha ao carregar dados do servidor.');
        
        cachedMasterData = await response.json();
        return cachedMasterData!;
    } catch (error) {
        console.error("Error fetching master data:", error);
        throw error;
    }
  },
  
  // Helpers to maintain compatibility or ease of use
  async getBrands(): Promise<Brand[]> {
      const data = await this.getMasterData();
      return data.brands;
  },

  async getConfig(): Promise<CaptainConfig> {
      const data = await this.getMasterData();
      return data.app_config;
  },
  
  clearCache() {
      cachedMasterData = null;
  }
};
