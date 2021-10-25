use anchor_lang::prelude::*;
// use anchor_spl::token::{self, CloseAccount, Mint, SetAuthority, TokenAccount, Transfer};
// use spl_token::instruction::AuthorityType;

declare_id!("HKf44ppDMwZrEp4rZVt8bmQtyBZNmTngCqQQRp8QcstX");

#[program]
pub mod anyrare {
  use super::*;

  pub fn initialize_asset(
    ctx: Context<InitializeAsset>,
    name: String,
    uri: String,
    custodian_account: Pubkey,
    // auditor_account: Pubkey,
    // founder_fee: u8,
    // founder_fee_decimal: u8,
  ) -> ProgramResult {
    let asset = &mut ctx.accounts.asset;
    asset.name = name;
    // asset.uri = uri;
    // asset.founder_account = *ctx.accounts.authority.key;
    // asset.custodian_account = custodian_account;
    // asset.auditor_account = auditor_account;
    // asset.founder_fee = founder_fee;
    // asset.founder_fee_decimal = founder_fee_decimal;

    Ok(())
  }
}

#[derive(Accounts)]
pub struct InitializeAsset<'info> {
  #[account(init, payer = user, space = 800)]
  pub asset: Account<'info, Asset>,
  #[account(mut)]
  pub user: Signer<'info>,
  pub system_program: Program<'info, System>,
}

#[account]
pub struct Asset {
  pub name: String,
  pub uri: String,
  pub founder_account: Pubkey,
  pub collector_account: Pubkey,
  pub custodian_account:Pubkey,
  pub auditor_account: Pubkey,
  pub platform_account: Pubkey,
  pub founder_fee: u8,
  pub founder_fee_decimal: u8,
  pub custodian_fee: u8,
  pub custodian_fee_decimal: u8,
  pub platform_fee: u8,
  pub platform_fee_decimal: u8,
  pub auditor_signed: bool,
  pub custodian_signed: bool,
  pub auction_is_open: bool,
  pub auction_end_time: u64,
  pub auction_escrow_account: Pubkey,
  pub auction_max_bid: u64,
  pub auction_max_bid_decimal: u8,
  pub auction_max_bid_account: Pubkey,
  pub offer_escrow_account: Pubkey,
  pub offer_max_bid: u64,
  pub offer_max_bid_decimal: u8,
  pub offer_max_bid_account: Pubkey,
}