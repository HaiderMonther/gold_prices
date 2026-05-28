import { Controller, Get, Post, Delete, Param, Body, UseGuards, Request } from '@nestjs/common';
import { ExpensesService } from './expenses.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('expenses')
@UseGuards(JwtAuthGuard)
export class ExpensesController {
  constructor(private service: ExpensesService) {}

  @Get() findAll(@Request() req: any) { return this.service.findAll(req.user?.tenantId); }
  @Get('stats') stats(@Request() req: any) { return this.service.getStats(req.user?.tenantId); }
  @Post() create(@Body() dto: any, @Request() req: any) { return this.service.create(dto, req.user?.id, req.user?.tenantId); }
  @Delete(':id') remove(@Param('id') id: string) { return this.service.remove(id); }
}
