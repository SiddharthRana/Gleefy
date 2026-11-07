import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Equals, IsString } from 'class-validator';
import { PLAN_IDS, SUBSCRIPTION_STATUSES } from '@mirthmix/plans';

export class DeleteAccountBody {
  @ApiProperty({ example: 'DELETE', description: 'Must be exactly "DELETE"' })
  @IsString()
  @Equals('DELETE', { message: 'Type DELETE to confirm account deletion.' })
  confirm: string;
}

class AccountPlanDto {
  @ApiProperty({ enum: PLAN_IDS }) id: string;
  @ApiProperty() name: string;
  @ApiProperty() paid: boolean;
  @ApiProperty({ enum: ['default', 'subscription'] }) source: 'default' | 'subscription';
}

class EntitlementsDto {
  @ApiProperty() premiumContent: boolean;
}

class AccountPurchaseDto {
  @ApiProperty({ enum: ['google_play', 'dodo'] }) provider: string;
  @ApiProperty({ enum: PLAN_IDS }) planId: string;
  @ApiProperty({
    enum: SUBSCRIPTION_STATUSES,
    description: 'active (unlocked) or on_hold (payment still pending)',
  })
  status: string;
  @ApiProperty({ type: String, nullable: true, format: 'date-time' }) purchasedAt: string | null;
}

export class AccountDtoClass {
  @ApiProperty({ format: 'uuid' }) id: string;
  @ApiPropertyOptional() email?: string;
  @ApiProperty({ format: 'date-time' }) createdAt: string;
  @ApiProperty({ type: AccountPlanDto }) plan: AccountPlanDto;
  @ApiProperty({ type: EntitlementsDto }) entitlements: EntitlementsDto;
  @ApiProperty({ description: 'Premium is a one-time unlock: it doesn’t run out' })
  lifetime: boolean;
  @ApiProperty({
    type: String,
    nullable: true,
    format: 'date-time',
    description: 'Re-check a timed entitlement after this moment; null for a one-time unlock',
  })
  validUntil: string | null;
  @ApiProperty({ type: [AccountPurchaseDto] }) purchases: AccountPurchaseDto[];
}

export class DeleteAccountResponse {
  @ApiProperty({
    enum: ['deleted', 'pending'],
    description: 'pending: the account is disabled; the sign-in record will be removed shortly',
  })
  status: 'deleted' | 'pending';
}
