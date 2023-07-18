// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '../interfaces/IERC20.sol';

library TransferHelper {
    // function safeTransferFrom(
    //     address token,
    //     address from,
    //     address to,
    //     uint256 value
    // ) internal {
    //     (bool success, bytes memory data) = token.call(
    //         abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
    //     );
    //     require(success && (data.length == 0 || abi.decode(data, (bool))), 'FBV1:STF');
    // }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'FBV1:ST');
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'FBV1:SA');
    }

    // function safeTransferETH(address to, uint256 value) internal {
    //     (bool success, ) = to.call{value: value}(new bytes(0));
    //     require(success, 'FB:STE');
    // }
    function trans(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (
            _token == 0xdAC17F958D2ee523a2206206994597C13D831ec7 || _token == 0x69bAb60997A2f5CbeE668E5087Dd9F91437206Bb
        ) {
            USDTERC20(_token).transfer(_to, _amount);
        } else {
            safeTransfer(_token, _to, _amount);
        }
    }

    function tokenApprove(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (
            _token == 0xdAC17F958D2ee523a2206206994597C13D831ec7 || _token == 0x69bAb60997A2f5CbeE668E5087Dd9F91437206Bb
        ) {
            USDTERC20(_token).approve(_to, _amount);
        } else {
            safeApprove(_token, _to, _amount);
        }
    }
}
