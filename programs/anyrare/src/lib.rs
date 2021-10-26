use anchor_lang::prelude::*;
use anchor_spl::token::{self, MintTo, SetAuthority, Transfer, InitializeAccount, InitializeMint};

declare_id!("6kM2aqzAUhn6TZjztdE5QZuRdNYosrxjbvBsAakQt6S");

mod asset_nft {
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
      freeze_authority
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

impl<'a, 'b, 'c, 'info> From<&mut ProxyInitializeMint<'info>>
  for CpiContext<'a, 'b, 'c, 'info, InitializeMint<'info>>
  {
    fn from(accounts: &mut ProxyInitializeMint<'info>) -> CpiContext<'a, 'b, 'c, 'info, InitializeMint<'info>> {
      let cpi_accounts = InitializeMint {
        mint: accounts.mint.clone(),
        rent: accounts.rent.clone(),
      };
      let cpi_program = accounts.token_program.clone();
      CpiContext::new(cpi_program, cpi_accounts)
    }
  }