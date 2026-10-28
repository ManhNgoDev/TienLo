import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateBugReportDto {
  @IsNotEmpty({ message: 'Tiêu đề báo cáo không được để trống' })
  @IsString()
  @MaxLength(200)
  title: string;

  @IsNotEmpty({ message: 'Nội dung mô tả không được để trống' })
  @IsString()
  @MaxLength(3000)
  description: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsString()
  screen?: string;

  @IsOptional()
  @IsString()
  userEmail?: string;

  @IsOptional()
  @IsString()
  userId?: string;

  @IsOptional()
  @IsString()
  deviceInfo?: string;

  @IsOptional()
  @IsString()
  stackTrace?: string;

  @IsOptional()
  @IsString()
  appVersion?: string;
}
