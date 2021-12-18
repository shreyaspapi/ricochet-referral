// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const [owner, randomPerson, anotherRandomPerson, randomPerson2] = await hre.ethers.getSigners();

  const RexReferral = await hre.ethers.getContractFactory("REXReferral");
  const referral = await RexReferral.deploy();

  await referral.deployed();

  console.log("Contract deployed to:", referral.address);

  let txn = await referral.applyForAffiliate("Something", "1");
  await txn.wait();
  
  txn = await referral.isAffiliateEnabled("1")
  // let waited = await txn.wait()
  console.log("Before verify affliate txn", txn)

  txn = await referral.verifyAffiliate("1")
  await txn.wait();

  txn = await referral.isAffiliateEnabled("1")
  console.log("After verify affliate", txn)

  txn = await referral.connect(randomPerson).registerReferredUser(randomPerson.address, "1")
  await txn.wait();

  myReferral = await referral.affiliates("1")
  console.log("myReferral totalRef", myReferral.totalRef.toNumber())

  txn = await referral.connect(anotherRandomPerson).registerReferredUser(anotherRandomPerson.address, "1")
  await txn.wait();

  myReferral = await referral.affiliates("1")
  console.log("myReferral totalRef", myReferral.totalRef.toNumber())

  organiUser = await referral.isUserOrganic(randomPerson2.address)
  console.log("Before randomPerson2 is organicUser", organiUser)
  txn = await referral.connect(randomPerson2).registerOrganicUser(randomPerson2.address)
  await txn.wait();
  organiUser = await referral.isUserOrganic(randomPerson2.address)
  console.log("After randomPerson2 is organicUser", organiUser)

  // txn = await referral.applyForAffiliate("Something", "1");
  // await txn.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
