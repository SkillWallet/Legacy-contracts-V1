//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

library Types {
    enum Template {
        OpenSource,
        Art,
        Local,
        Other
    }

    enum Action {
        Activate,
        Login,
        CreateGig,
        TakeGig,
        SubmitGig,
        CompleteGig
    }

    struct SWValidationRequest {
        address caller;
        Types.Action action;
        Types.Params params;
    }

    struct Params {
        string[] stringParams;
        uint256[] intParams;
        address[] addressParams;
    }
    
    struct PartnersAgreementData {
        uint256 version;
        address owner;
        address communityAddress;
        address[] partnersContracts;
        uint256 rolesCount;
        address interactionContract;
        address membershipContract;
        uint256 interactionsCount;
    }
}
