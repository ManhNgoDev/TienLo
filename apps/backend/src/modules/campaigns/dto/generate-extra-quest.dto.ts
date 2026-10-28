import { IsArray, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class GenerateExtraQuestDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  goalPrompt: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  existingTitles?: string[];

  @IsOptional()
  @IsString()
  campaignId?: string;
}
