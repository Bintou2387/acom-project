export class CreateAnnonceDto {
  title: string;
  description: string;
  price: number;
  category: string; // On utilise string simple maintenant
  phone_number: string;
  
  // Champs optionnels
  detailsAuto?: any;
  detailsImmo?: any;
  detailsHotel?: any;
  latitude?: number;
  longitude?: number;
  
  // Le champ images est géré à part, mais on peut le déclarer
  images?: string[];
}