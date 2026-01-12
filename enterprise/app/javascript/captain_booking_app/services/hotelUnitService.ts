
import type { HotelUnit } from '../types.ts';

const API_BASE_URL = '/public/api/v1/captain';

// Helper to fetch all master data if needed, but here we can just fetch brands
// Actually, to get all units, we need the brands.
const fetchMasterData = async () => {
    // TODO: Dynamic Account ID
    const response = await fetch(`${API_BASE_URL}/master_data?account_id=1`);
    if (!response.ok) throw new Error('Falha ao carregar dados do servidor.');
    return response.json();
};

export const hotelUnitService = {
  async getAllUnits(): Promise<HotelUnit[]> {
    const data = await fetchMasterData();
    // Flatten units from brands
    const allUnits: HotelUnit[] = [];
    data.brands.forEach((brand: any) => {
        if (brand.units) {
            brand.units.forEach((u: any) => {
                allUnits.push({
                    id: u.id,
                    name: u.name,
                    brandId: u.captain_brand_id, // Chatwoot model field
                    visible_suite_categories: u.visible_suite_categories || [],
                    suite_category_images: u.suite_category_images || [],
                });
            });
        }
    });
    return allUnits;
  },
  
  async getUnitsByBrand(brandId: number): Promise<HotelUnit[]> {
    // We could optimize by not fetching everything, but for now MasterData is fine
    const allUnits = await this.getAllUnits();
    return allUnits.filter(u => u.brandId === brandId);
  },

  async addUnit(newUnit: Omit<HotelUnit, 'id'>): Promise<HotelUnit> {
    throw new Error("Operação não permitida na interface pública.");
  },

  async updateUnit(updatedUnit: HotelUnit): Promise<HotelUnit> {
    throw new Error("Operação não permitida na interface pública.");
  },

  async deleteUnit(unitId: number): Promise<void> {
    throw new Error("Operação não permitida na interface pública.");
  },
};
