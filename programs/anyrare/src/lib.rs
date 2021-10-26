use anchor_lang::prelude::*;
use anchor_spl::token::{
  self,
  Burn,
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

  pub fn proxy_set_authority(
    ctx: Context<ProxySetAuthority>,
    authority_type: AuthorityType,
    new_authority: Option<Pubkey>,
  ) -> ProgramResult {
    token::set_authority(
      ctx.accounts.into(),
      authority_type.into(),
      new_authority,
    )
  }

  pub fn proxy_transfer(
    ctx: Context<ProxyTransfer>,
    amount: u64,
  ) -> ProgramResult {
    token::transfer(
      ctx.accounts.into(),
      amount,
    )
  }

  pub fn proxy_burn(
    ctx: Context<ProxyBurn>,
    amount: u64,
  ) -> ProgramResult {
    token::burn(
      ctx.accounts.into(),
      amount
    )
  }
}

#[derive(AnchorSerialize, AnchorDeserialize)]
pub enum AuthorityType {
  MintTokens,
  FreezeAccount,
  AccountOwner,
  CloseAccount,
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

#[derive(Accounts)]
pub struct ProxySetAuthority<'info> {
  #[account(signer)]
  pub current_authority: AccountInfo<'info>,
  #[account(mut)]
  pub account_or_mint: AccountInfo<'info>,
  pub token_program: AccountInfo<'info>,
}

#[derive(Accounts)]
pub struct ProxyTransfer<'info> {
  #[account(signer)]
  pub authority: AccountInfo<'info>,
  #[account(mut)]
  pub from: AccountInfo<'info>,
  #[account(mut)]
  pub to: AccountInfo<'info>,
  pub token_program: AccountInfo<'info>,
}

#[derive(Accounts)]
pub struct ProxyBurn<'info> {
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

impl<'a, 'b, 'c, 'info> From<&mut ProxySetAuthority<'info>>
  for CpiContext<'a, 'b, 'c, 'info, SetAuthority<'info>>
  {
    fn from(accounts: &mut ProxySetAuthority<'info>)
      -> CpiContext<'a, 'b, 'c, 'info, SetAuthority<'info>> {
        let cpi_accounts = SetAuthority {
          account_or_mint: accounts.account_or_mint.clone(),
          current_authority: accounts.current_authority.clone(),
        };
        let cpi_program = accounts.token_program.clone();
        CpiContext::new(cpi_program, cpi_accounts)
      }
  }

impl<'a, 'b, 'c, 'info> From<&mut ProxyTransfer<'info>>
  for CpiContext<'a, 'b, 'c, 'info, Transfer<'info>>
  {
    fn from(accounts: &mut ProxyTransfer<'info>)
      -> CpiContext<'a, 'b, 'c, 'info, Transfer<'info>> {
        let cpi_accounts = Transfer {
          from: accounts.from.clone(),
          to: accounts.to.clone(),
          authority: accounts.authority.clone(),
        };
        let cpi_program = accounts.token_program.clone();
        CpiContext::new(cpi_program, cpi_accounts)
      }
  }

impl<'a, 'b, 'c, 'info> From<&mut ProxyBurn<'info>>
  for CpiContext<'a, 'b, 'c, 'info, Burn<'info>>
  {
    fn from(accounts: &mut ProxyBurn<'info>)
      -> CpiContext<'a, 'b, 'c, 'info, Burn<'info>> {
        let cpi_accounts = Burn {
          mint: accounts.mint.clone(),
          to: accounts.to.clone(),
          authority: accounts.authority.clone(),
        };
        let cpi_program = accounts.token_program.clone();
        CpiContext::new(cpi_program, cpi_accounts)
      }
  }

impl From<AuthorityType> for spl_token::instruction::AuthorityType {
  fn from(authority_ty: AuthorityType) -> spl_token::instruction::AuthorityType {
    match authority_ty {
      AuthorityType::MintTokens => spl_token::instruction::AuthorityType::MintTokens,
      AuthorityType::FreezeAccount => spl_token::instruction::AuthorityType::FreezeAccount,
      AuthorityType::AccountOwner => spl_token::instruction::AuthorityType::AccountOwner,
      AuthorityType::CloseAccount => spl_token::instruction::AuthorityType::CloseAccount,
    }
  }
}