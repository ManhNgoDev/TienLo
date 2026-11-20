export class SendUpdateNoticeDto {
  recipientEmail?: string;
  updateVersion?: string;
  subject?: string;
  fixedIssues?: string[];
  customMessage?: string;
  adminSecret?: string;
}
