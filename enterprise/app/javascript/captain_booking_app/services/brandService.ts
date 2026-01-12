import type { Brand } from '../types.ts';

const API_BASE_URL = '/public/api/v1/captain';

export const brandService = {
  async getAllBrands(): Promise<Brand[]> {
    // We fetch from the monolithic master_data endpoint
    // In a real app, this should probably be cached or passed down from a parent context
    // but for porting, we just fetch it.
    
    // Hardcoded account_id=1 for now. 
    // TODO: Inject via window global or URL param. 
    const response = await fetch(`${API_BASE_URL}/master_data?account_id=1`);
    
    if (!response.ok) throw new Error('Falha ao carregar dados do servidor.');
    
    const data = await response.json();
    return data.brands; // Brands already include units in our serializer
  },

  async addBrand(newBrand: Omit<Brand, 'id'>): Promise<Brand> {
    throw new Error("Operação não permitida na interface pública.");
  },

  async updateBrand(updatedBrand: Brand): Promise<Brand> {
    throw new Error("Operação não permitida na interface pública.");
  },

  async deleteBrand(brandId: number): Promise<void> {
    throw new Error("Operação não permitida na interface pública.");
  },
};