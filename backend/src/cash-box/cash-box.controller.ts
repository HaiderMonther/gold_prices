import { Controller, Get, Post, Body, Query, UseGuards, Request } from '@nestjs/common';
import { CashBoxService } from './cash-box.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CashBoxType } from './cash-box.entity';

@Controller('cash-box')
@UseGuards(JwtAuthGuard)
export class CashBoxController {
  constructor(private service: CashBoxService) {}

  @Get()
  findAll(@Request() req: any, @Query('dateFrom') dateFrom?: string, @Query('dateTo') dateTo?: string) {
    return this.service.findAll(req.user?.tenantId, dateFrom, dateTo);
  }

  @Get('balance')
  getBalance(@Request() req: any) {
    return this.service.getBalance(req.user?.tenantId);
  }

  @Get('daily')
  getDailySummary(@Request() req: any, @Query('date') date?: string) {
    return this.service.getDailySummary(req.user?.tenantId, date);
  }

  @Post()
  addManualEntry(@Body() body: { type: CashBoxType; amount: number; description: string }, @Request() req: any) {
    return this.service.addEntry({ ...body, tenant_id: req.user?.tenantId });
  }
}
