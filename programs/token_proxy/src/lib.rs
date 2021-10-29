use anchor_lang::prelude::*;
use anchor_spl::token::{self, MintTo};

declare_id!("6rjgvbtaPZLSiaiH7pUSsriRxg9it7YtUzdkvKXDTDLH");

#[program]
mod token_proxy {
  use super::*;

  pub fn create(
    ctx: Context<Create>, 
    founder: Pubkey,
    custodian: Pubkey,
    auditor: Pubkey,
    token: Pubkey,
  ) -> Result<()> {
    let contract = &mut ctx.accounts.contract;
    contract.founder = founder;
    contract.custodian = custodian;
    contract.auditor = auditor;
    contract.token = token;
    contract.is_custodian_signed = false;
    contract.is_auditor_signed = false;
    
    Ok(())
  }

  pub fn auditor_sign(
    ctx: Context<AuditorSign>
  ) -> Result<()> {
    let contract = &mut ctx.accounts.contract;
    contract.is_auditor_signed = true;

    Ok(())
  }

  pub fn custodian_sign(
    ctx: Context<CustodianSign>
  ) -> Result<()> {
    let contract = &mut ctx.accounts.contract;
    contract.is_custodian_signed = true;

    Ok(())
  }

  // pub fn mint_NFT(
  //   ctx: Context<>
  // ) -> Result<()> {
    // token:mint_to(ctx.accounts.into());

  //   Ok(())
  // }
}

#[derive(Accounts)]
pub struct Create<'info> {
  #[account(init, payer = user, space = 8 + 1000)]
  pub contract: Account<'info, Contract>,
  #[account(mut)]
  pub user: Signer<'info>,
  pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct AuditorSign<'info> {
  #[account(mut, has_one = auditor)]
  pub contract: Account<'info, Contract>,
  pub auditor: Signer<'info>,
}

#[derive(Accounts)]
pub struct CustodianSign<'info> {
  #[account(mut, has_one = custodian)]
  pub contract: Account<'info, Contract>,
  pub custodian: Signer<'info>,
}

#[derive(Accounts)]
pub struct TokenMintTo<'info> {
  #[account(mut)]
  pub mint: AccountInfo<'info>,
  #[account(mut)]
  pub to: AccountInfo<'info>,
  pub auditor: Signer<'info>,
  pub token_program: AccountInfo<'info>,
}

#[account]
pub struct Contract {
  pub founder: Pubkey,
  pub custodian: Pubkey,
  pub auditor: Pubkey,
  pub token: Pubkey,
  pub is_custodian_signed: bool,
  pub is_auditor_signed: bool,
}

#[error]
pub enum ErrorCode {
  #[msg("You are not authorized to perform this action.")]
  Unauthorized,
}