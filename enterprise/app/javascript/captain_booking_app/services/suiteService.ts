
import type { Suite } from '../types.ts';

const API_BASE_URL = '/public/api/v1/captain';

const fetchMasterData = async () => {
    const response = await fetch(`${API_BASE_URL}/master_data?account_id=1`);
    if (!response.ok) throw new Error('Falha ao carregar dados do servidor.');
    return response.json();
};

export const suiteService = {
  async getAllSuites(): Promise<Suite[]> {
    const data = await fetchMasterData();
    // Map snake_case to camelCase if needed, but our model returns snake_case usually
    return (data.suites || []).map((s: any) => ({
        id: s.id,
        api_id: s.api_id,
        name: s.name,
        category: s.category,
        unitIds: s.unit_ids || []
    }));
  },

  async addSuite(newSuite: Omit<Suite, 'id'>): Promise<Suite> {
    throw new Error("Operação não permitida na interface pública.");
  },

  async updateSuite(updatedSuite: Suite): Promise<Suite> {
    throw new Error("Operação não permitida na interface pública.");
  },

  async deleteSuite(suiteId: number): Promise<void> {
    throw new Error("Operação não permitida na interface pública.");
  },

  async getRandomSuiteApiIdFromCategory(category: string, unitId: number): Promise<number | null> {
    try {
        const suites = await this.getAllSuites();
        
        // Filter by category
        const suitesInCategory = suites.filter(s => s.category === category);

        if (!suitesInCategory || suitesInCategory.length === 0) {
            console.warn(`Nenhuma suíte encontrada no banco de dados para a categoria '${category}'.`);
            return null;
        }

        // Filter by unit availability
        const availableSuites = suitesInCategory.filter(suite =>
            suite.unitIds && suite.unitIds.includes(unitId)
        );

        if (availableSuites.length === 0) {
            console.warn(`Nenhuma suíte da categoria '${category}' disponível para a unidade '${unitId}'.`);
            return null;
        }

        // Select random
        const randomIndex = Math.floor(Math.random() * availableSuites.length);
        const apiId = availableSuites[randomIndex].api_id;
        // api_id is string in DB but number in frontend interface typically?
        return apiId ? parseInt(String(apiId), 10) : null;
    } catch (e) {
        console.error("Error finding suite:", e);
        return null;
    }
  },
};
