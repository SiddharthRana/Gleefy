import { Body, Controller, Get, Headers, HttpCode, Param, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiProperty, ApiTags } from '@nestjs/swagger';
import { SkipThrottle, Throttle } from '@nestjs/throttler';
import { IsString, MaxLength, MinLength } from 'class-validator';
import type { Request } from 'express';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser, Public } from '../auth/decorators';
import { ApiErrorDto } from '../common/api-error';
import { BillingService } from './billing.service';

class PlayVerifyBody {
  @ApiProperty({ description: 'Google Play purchase token' })
  @IsString()
  @MinLength(10)
  @MaxLength(4096)
  purchaseToken: string;
}

class UrlDto {
  @ApiProperty() url: string;
}

class WebBillingDto {
  @ApiProperty({ enum: ['none', 'dodo'] }) provider: 'none' | 'dodo';
  @ApiProperty() available: boolean;
}

class PlayBillingDto {
  @ApiProperty() available: boolean;
  @ApiProperty() packageName: string;
  @ApiProperty({ description: 'One-time in-app product id of the Premium unlock' })
  productId: string;
}

class BillingConfigDtoClass {
  @ApiProperty({ description: 'Paid plans switched on (billing feature flag)' }) enabled: boolean;
  @ApiProperty({ type: WebBillingDto }) web: WebBillingDto;
  @ApiProperty({ type: PlayBillingDto }) googlePlay: PlayBillingDto;
}

class AccountRefDto {
  @ApiProperty({ description: 'Pass as obfuscatedAccountId (applicationUserName) when purchasing' })
  accountRef: string;
}

class PlayVerifyResponse {
  @ApiProperty() planId: string;
  @ApiProperty() status: string;
  @ApiProperty({
    description: 'True when Premium was already bought on another channel (warn the user)',
  })
  duplicatePurchase: boolean;
}

type RawRequest = Request & { rawBody?: Buffer };

@ApiTags('billing')
@Controller('billing')
export class BillingController {
  constructor(private readonly billing: BillingService) {}

  @Get('config')
  @Public()
  @ApiOkResponse({ type: BillingConfigDtoClass })
  config(): Promise<BillingConfigDtoClass> {
    return this.billing.config();
  }

  /** Start a web checkout for the Premium unlock with the configured Merchant of Record. */
  @Post('checkout')
  @HttpCode(200)
  @ApiBearerAuth()
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @ApiOkResponse({ type: UrlDto, description: 'Hosted checkout URL to redirect to' })
  checkout(@CurrentUser() user: AuthUser): Promise<UrlDto> {
    return this.billing.checkout(user);
  }

  @Get('google-play/account-ref')
  @ApiBearerAuth()
  @ApiOkResponse({ type: AccountRefDto })
  async accountRef(@CurrentUser() user: AuthUser): Promise<AccountRefDto> {
    return { accountRef: await this.billing.playAccountRef(user) };
  }

  /** The app reports a Play purchase; the server verifies it with Google and acknowledges it. */
  @Post('google-play/verify')
  @HttpCode(200)
  @ApiBearerAuth()
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  @ApiOkResponse({ type: PlayVerifyResponse })
  verify(@CurrentUser() user: AuthUser, @Body() body: PlayVerifyBody): Promise<PlayVerifyResponse> {
    return this.billing.verifyPlayPurchase(user, body.purchaseToken);
  }

  /** Google Play Real-time Developer Notifications (Cloud Pub/Sub push). */
  @Post('google-play/rtdn')
  @Public()
  @SkipThrottle()
  @HttpCode(200)
  @ApiOkResponse({ type: ApiErrorDto, description: 'Acknowledged' })
  rtdn(@Headers('authorization') authorization: string | undefined, @Body() body: unknown) {
    return this.billing.handleRtdn(authorization, body);
  }

  /** Web provider webhooks (signature-verified against the raw body). */
  @Post('webhooks/:provider')
  @Public()
  @SkipThrottle()
  @HttpCode(200)
  webhook(@Param('provider') provider: string, @Req() req: RawRequest) {
    return this.billing.handleWebhook(provider, {
      rawBody: req.rawBody ?? Buffer.alloc(0),
      headers: req.headers,
    });
  }
}
