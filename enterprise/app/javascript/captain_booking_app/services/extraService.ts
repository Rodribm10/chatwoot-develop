import { ExtraItem } from '../types.ts';

const API_BASE_URL = '/public/api/v1/captain';

const fetchMasterData = async () => {
    const response = await fetch(`${API_BASE_URL}/master_data?account_id=1`);
    if (!response.ok) throw new Error('Falha ao carregar dados do servidor.');
    return response.json();
};

export const extraService = {
  // Now async because it fetches from API
  async getExtras(): Promise<ExtraItem[]> {
    try {
      const data = await fetchMasterData();
      return data.extras || [];
    } catch (e) {
      console.error("Erro ao carregar extras:", e);
      return [];
    }
  },

  // Read-only in public app
  saveExtras(extras: ExtraItem[]): void {
     console.warn("saveExtras ignored in public mode");
  },

  addExtra(extra: Omit<ExtraItem, 'id'>): ExtraItem {
    throw new Error("Read-only service");
  },

  updateExtra(updatedExtra: ExtraItem): ExtraItem {
    throw new Error("Read-only service");
  },

  deleteExtra(id: string): void {
    throw new Error("Read-only service");
  },
  
  toggleStatus(id: string): ExtraItem | null {
     throw new Error("Read-only service");
  }
};
