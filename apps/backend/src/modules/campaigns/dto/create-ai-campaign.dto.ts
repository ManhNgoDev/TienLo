import { IsNotEmpty, IsNumber, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateAiCampaignDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  goalPrompt: string;

  @IsOptional()
  @IsNumber()
  durationDays?: number;
}
