import { Controller, Get, Post, Query, Param, UseGuards, Request } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('reports')
@UseGuards(JwtAuthGuard)
export class ReportsController {
  constructor(private service: ReportsService) {}

  @Get('dashboard') dashboard(@Request() req: any) { return this.service.getDashboardStats(req.user?.tenantId); }
  @Get('monthly-sales') monthlySales(@Request() req: any) { return this.service.getMonthlySales(req.user?.tenantId); }
  @Post('reset') reset(@Request() req: any) { return this.service.resetSystem(req.user?.tenantId); }

  // Kimia-style reports
  @Get('account-statement/:customerId')
  accountStatement(
    @Param('customerId') customerId: string,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ) {
    return this.service.getAccountStatement(customerId, dateFrom, dateTo);
  }

  @Get('daily-trading')
  dailyTrading(@Request() req: any, @Query('date') date?: string) {
    return this.service.getDailyTrading(req.user?.tenantId, date);
  }

  @Get('inventory-summary')
  inventorySummary(@Request() req: any) {
    return this.service.getInventorySummary(req.user?.tenantId);
  }

  @Get('sales-vs-purchases')
  salesVsPurchases(
    @Request() req: any,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ) {
    return this.service.getSalesVsPurchases(req.user?.tenantId, dateFrom, dateTo);
  }

  @Get('profit')
  profitReport(
    @Request() req: any,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ) {
    return this.service.getProfitReport(req.user?.tenantId, dateFrom, dateTo);
  }

  @Get('debts')
  debtReport(@Request() req: any) {
    return this.service.getDebtReport(req.user?.tenantId);
  }
}
