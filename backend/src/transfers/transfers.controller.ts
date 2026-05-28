import { Controller, Get, Post, Delete, Body, Param, UseGuards, Request } from '@nestjs/common';
import { TransfersService } from './transfers.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('transfers')
@UseGuards(JwtAuthGuard)
export class TransfersController {
  constructor(private service: TransfersService) {}

  @Get()
  findAll(@Request() req: any) {
    return this.service.findAll(req.user?.tenantId);
  }

  @Post()
  create(@Body() body: any, @Request() req: any) {
    return this.service.create({ ...body, tenant_id: req.user?.tenantId });
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.service.remove(id);
  }
}
