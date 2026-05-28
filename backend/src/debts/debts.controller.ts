import { Controller, Get, Post, Param, Body, UseGuards, Request } from '@nestjs/common';
import { DebtsService } from './debts.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('debts')
@UseGuards(JwtAuthGuard)
export class DebtsController {
  constructor(private service: DebtsService) {}

  @Get() findAll(@Request() req: any) { return this.service.findAll(req.user?.tenantId); }
  @Get('unpaid') findUnpaid(@Request() req: any) { return this.service.findUnpaid(req.user?.tenantId); }
  @Post(':id/pay') pay(@Param('id') id: string, @Body() dto: { amount: number }) {
    return this.service.payDebt(id, dto.amount);
  }
}
