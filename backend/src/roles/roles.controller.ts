import { Controller, Get, Post, Put, Delete, Param, Body, UseGuards } from '@nestjs/common';
import { RolesService } from './roles.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('roles')
@UseGuards(JwtAuthGuard)
export class RolesController {
  constructor(private service: RolesService) {}

  @Get()
  findAllRoles() {
    return this.service.findAllRoles();
  }

  @Get('permissions')
  findAllPermissions() {
    return this.service.findAllPermissions();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findRoleById(id);
  }

  @Post()
  create(@Body() dto: any) {
    return this.service.createRole(dto);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: any) {
    return this.service.updateRole(id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.service.deleteRole(id);
  }
}
