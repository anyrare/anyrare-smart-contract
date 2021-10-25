use anchor_lang::prelude::*;

declare_id!("5XF9u5rmuxp7z8Prf5GjPvViMzMQRR9VvoUBC15zXBFT");

#[program]
pub mod nft_asset {
  use super::*;

  pub fn create(ctx: Context<Create>, 
    name: String, 
    founder_id: Pubkey,
    collector_id: Pubkey,
    auditor_id: Pubkey,
    custodian_id: Pubkey,
    collection_id: Pubkey,
    platform_id: Pubkey,
    founder_fee: u8,
    custodian_fee: u8,
    platform_fee: u8,
    uri: String,

  ) -> ProgramResult {
    let asset = &mut ctx.accounts.asset;
    asset.name = name;
    asset.founder_id = founder_id;
    asset.collection_id = collector_id;
    asset.auditor_id = auditor_id;
    asset.custodian_id = custodian_id;
    asset.collection_id = collection_id;
    asset.platform_id = platform_id;
    asset.founder_fee = founder_fee;
    asset.custodian_fee = custodian_fee;
    asset.platform_fee = platform_fee;
    asset.uri = uri;
    Ok(())
  }

  pub fn transfer(ctx: Context<Transfer>, receiver: Pubkey) -> ProgramResult {
    let asset = &mut ctx.accounts.asset;
    asset.founder_id = receiver;
    Ok(())
  }

  pub fn auditor_sign(ctx: Context<AuditorSign>) -> ProgramResult {
    let asset = &mut ctx.accounts.asset;
    asset.auditor_signed = true;
    Ok(())
  }
}

#[account]
pub struct Asset {
  pub name: String,
  pub founder_id: Pubkey,
  pub collector_id: Pubkey,
  pub auditor_id: Pubkey,
  pub custodian_id: Pubkey,
  pub collection_id: Pubkey,
  pub platform_id: Pubkey,
  pub founder_fee: u8,
  pub custodian_fee: u8,
  pub platform_fee: u8,
  pub founder_signed: bool,
  pub auditor_signed: bool,
  pub status: String,
  pub uri: String,
}

// #[account]
// pub struct Asset {
//   pub asset_name: String,
//   pub founder_id: Pubkey,
//   pub collector_id: Pubkey,
//   pub auditor_id: Pubkey,
//   pub custodian_id: Pubkey,
//   pub collection_id: Pubkey,
//   pub platform_id: Pubkey,
//   pub founder_fee: u8,
//   pub custodian_fee: u8,
//   pub platform_fee: u8,
//   pub custodian_contract: String,
//   pub auditor_report: String,
//   pub image_0: String,
//   pub image_1: String,
//   pub image_2: String,
//   pub image_3: String,
//   pub image_4: String,
//   pub image_6: String,
//   pub note: String,
//   pub uri: String,
// }


#[derive(Accounts)]
pub struct Create<'info> {
  #[account(init, payer = user, space = 8 + 500)]
  pub asset: Account<'info, Asset>,
  #[account(mut)]
  pub user: Signer<'info>,
  pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct Transfer<'info> {
  #[account(mut, has_one = founder_id)]
  pub asset: Account<'info, Asset>,
  pub founder_id: Signer<'info>,
}

#[derive(Accounts)]
pub struct AuditorSign<'info> {
  #[account(mut, has_one = auditor_id)]
  pub asset: Account<'info, Asset>,
  pub auditor_id: Signer<'info>,
}