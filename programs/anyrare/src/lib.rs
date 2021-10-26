use anchor_lang::prelude::*;
use anchor_spl::token::{
  self,
  MintTo,
  SetAuthority,
  Transfer,
  InitializeAccount,
  InitializeMint};

declare_id!("6kM2aqzAUhn6TZjztdE5QZuRdNYosrxjbvBsAakQt6S");

mod token_proxy {
  use super::*;

  pub fn proxy_initialize_mint(
    ctx: Context<ProxyInitializeMint>,
    decimals: u8,
    authority: &Pubkey,
    freeze_authority: Option<&Pubkey>,
  ) -> ProgramResult {
    token::initialize_mint(
      ctx.accounts.into(),
      decimals,
      authority,
      freeze_authority,
    )
  }

  pub fn proxy_initialize_account(
    ctx: Context<ProxyInitializeAccount>,
  ) -> ProgramResult {
    token::initialize_account(
      ctx.accounts.into(),
    )
  }

  pub fn proxy_mint_to(
    ctx: Context<ProxyMintTo>,
    amount: u64
  ) -> ProgramResult {
    token::mint_to(
      ctx.accounts.into(),
      amount,
    )
  }
}

#[derive(Accounts)]
pub struct ProxyInitializeMint<'info> {
  #[account(signer)]
  pub authority: AccountInfo<'info>,
  #[account(mut)]
  pub account: AccountInfo<'info>,
  #[account(mut)]
  pub mint: AccountInfo<'info>,
  #[account(mut)]
  pub rent: AccountInfo<'info>,
  pub token_program: AccountInfo<'info>,
}

#[derive(Accounts)]
pub struct ProxyInitializeAccount<'info> {
  #[account(signer)]
  pub authority: AccountInfo<'info>,
  #[account(mut)]
  pub account: AccountInfo<'info>,
  #[account(mut)]
  pub mint: AccountInfo<'info>,
  #[account(mut)]
  pub rent: AccountInfo<'info>,
  pub token_program: AccountInfo<'info>,
}

#[derive(Accounts)]
pub struct ProxyMintTo<'info> {
  #[account(signer)]
  pub authority: AccountInfo<'info>,
  #[account(mut)]
  pub mint: AccountInfo<'info>,
  #[account(mut)]
  pub to: AccountInfo<'info>,
  pub token_program: AccountInfo<'info>,
}

impl<'a, 'b, 'c, 'info> From<&mut ProxyInitializeMint<'info>>
  for CpiContext<'a, 'b, 'c, 'info, InitializeMint<'info>>
  {
    fn from(accounts: &mut ProxyInitializeMint<'info>) 
      -> CpiContext<'a, 'b, 'c, 'info, InitializeMint<'info>> {
      let cpi_accounts = InitializeMint {
        mint: accounts.mint.clone(),
        rent: accounts.rent.clone(),
      };
      let cpi_program = accounts.token_program.clone();
      CpiContext::new(cpi_program, cpi_accounts)
    }
  }

impl<'a, 'b, 'c, 'info> From<&mut ProxyInitializeAccount<'info>>
  for CpiContext<'a, 'b, 'c, 'info, InitializeAccount<'info>>
  {
    fn from(accounts: &mut ProxyInitializeAccount<'info>) 
      -> CpiContext<'a, 'b, 'c, 'info, InitializeAccount<'info>> {
      let cpi_accounts = InitializeAccount {
        account: accounts.account.clone(),
        mint: accounts.mint.clone(),
        authority: accounts.authority.clone(),
        rent: accounts.rent.clone(),
      };
      let cpi_program = accounts.token_program.clone();
      CpiContext::new(cpi_program, cpi_accounts)
    }
  }

impl<'a, 'b, 'c, 'info> From<&mut ProxyMintTo<'info>>
  for CpiContext<'a, 'b, 'c, 'info, MintTo<'info>>
  {
    fn from(accounts: &mut ProxyMintTo<'info>)
      -> CpiContext<'a, 'b, 'c, 'info, MintTo<'info>> {
        let cpi_accounts = MintTo {
          mint: accounts.mint.clone(),
          to: accounts.to.clone(),
          authority: accounts.authority.clone(),
        };
        let cpi_program = accounts.token_program.clone();
        CpiContext::new(cpi_program, cpi_accounts)
      }
  }