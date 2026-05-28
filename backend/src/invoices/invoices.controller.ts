import { Controller, Get, Post, Delete, Param, Body, UseGuards, Request } from '@nestjs/common';
import { InvoicesService } from './invoices.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('invoices')
@UseGuards(JwtAuthGuard)
export class InvoicesController {
  constructor(private service: InvoicesService) {}

  @Get() findAll(@Request() req: any) { return this.service.findAll(req.user?.tenantId); }
  @Get(':id') findOne(@Param('id') id: string) { return this.service.findOne(id); }
  @Post() create(@Body() dto: any, @Request() req: any) {
    return this.service.create({ ...dto, user_id: req.user?.id, tenant_id: req.user?.tenantId });
  }
  @Delete(':id') remove(@Param('id') id: string) { return this.service.remove(id); }
}
