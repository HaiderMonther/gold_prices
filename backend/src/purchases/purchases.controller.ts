import { Controller, Get, Post, Delete, Param, Body, UseGuards, Request } from '@nestjs/common';
import { PurchasesService } from './purchases.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('purchases')
@UseGuards(JwtAuthGuard)
export class PurchasesController {
  constructor(private service: PurchasesService) {}

  @Get() findAll(@Request() req: any) { return this.service.findAll(req.user?.tenantId); }
  @Post() create(@Body() dto: any, @Request() req: any) { return this.service.create(dto, req.user?.id, req.user?.tenantId); }
  @Delete(':id') remove(@Param('id') id: string) { return this.service.remove(id); }
}
