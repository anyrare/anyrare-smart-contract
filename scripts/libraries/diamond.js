const FacetCutAction = { Add: 0, Replace: 1, Remove: 2 };

const getSelectors = (contract) => {
  const signatures = Object.keys(contract.interface.functions);
  const selectors = signatures.reduce((acc, val) => {
    if (val !== 'init(bytes)') {
      acc.push(contract.interface.getSighash(val));
    }
    return acc;
  }, []);

  selectors.contract = contract;
  selectors.remove = remove;
  selectors.get = get;
  return selectors;
}

const getSelector = (func) => {
  const abiInterface = new ethers.utils.Interface([func]);
  return abiInterface.getSighash(ethers.utils.Fragment.from(func));
}

const remove = (functionNames) => {
  const selectors = this.filter((v) => {
    for (const functionName of functionNames) {
      if (v === this.contract.interface.getSighash(functionName)) {
        return false;
      }
    }
    return true;
  });
  selectors.contract = this.contract;
  selectors.remove = this.remove;
  selectors.get = this.get;
  return selectors;
}

const get = (functionNames) => {
  const selectors = this.filter((v) => {
    for (const functionName of functionNames) {
      if (v === this.contract.interface.getSighash(functionName)) {
        return true;
      }
    }
  });
  selectors.contract = this.contract;
  selectors.remove = this.remove;
  selectors.get = this.get;
  return selectors;
}

const removeSelectors = (selectors, signatures) => {
  const iface = new ethers.utils.Interface(signatures.map(v => 'function ' + v));
  const removeSelectors = signatures.map(v => iface.getSighash(v));
  selectors = selectors.filter(v => !removeSelectors.includes(v));
  return selectors;
}

const findAddressPosistionInFacets = (facetAddress, facets) => {
  for (let i = 0; i < facets.length; i++) {
    if (facets[i].facetAddress === facetAddress) {
      return i;
    }
  }
}

exports.getSelectors = getSelectors;
exports.getSelector = getSelector;
exports.FacetCutAction = FacetCutAction;
exports.remove = remove;
exports.removeSelectors = removeSelectors;
exports.findAddressPosistionInFacets = findAddressPosistionInFacets;
