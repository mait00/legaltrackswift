import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, StatusBar, View, TouchableOpacity, FlatList, Text } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {GRAY_LIGHT, MAIN_COLOR} from './../../styles/colors';

const PracticeScreen = ({bills, getBills, setSelectedBill, getBalance}) => {

	const navigation = useNavigation();

	return (
        <View style={{
            flex: 1,
            backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'center',
        }}>
			
		</View>
	);
};

const mstp = (state: RootState) => ({
	// bills: state.bills.bills,
});

const mdtp = (dispatch: Dispatch) => ({
    // getBills: () => dispatch.bills.getBills(),
	// setSelectedBill: payload => dispatch.bills.setSelectedBill(payload),
	// getBalance: payload => dispatch.bills.getBalance(payload),
});

export default connect(mstp, mdtp)(PracticeScreen);
