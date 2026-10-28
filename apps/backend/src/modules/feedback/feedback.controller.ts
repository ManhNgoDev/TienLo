import { Body, Controller, Get, Post, HttpCode, HttpStatus } from '@nestjs/common';
import { FeedbackService } from './feedback.service.js';
import { CreateBugReportDto } from './dto/create-bug-report.dto.js';

@Controller('feedback')
export class FeedbackController {
  constructor(private readonly feedbackService: FeedbackService) {}

  @Post('report')
  @HttpCode(HttpStatus.OK)
  async reportBug(@Body() dto: CreateBugReportDto) {
    return this.feedbackService.reportBug(dto);
  }

  @Get('recent')
  async getRecentReports() {
    return this.feedbackService.getRecentReports();
  }
}
