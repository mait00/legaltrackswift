import React, { useCallback, useEffect, useRef } from 'react';
import { Linking, Image, View, TouchableOpacity, ScrollView, Text, Share, Alert } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {GRAY_LIGHT, MAIN_COLOR} from './../../styles/colors';
import { colors } from '../../styles';
import SidesView from '../../components/Case/SidesView';
import EventsView from '../../components/Case/EventsView';
import { APP_NAME } from '../../constants';
import Dialog from "react-native-dialog";

const ScannerScreen = ({route}) => {

	const navigation = useNavigation();
	// const [body, setBody] = React.useState(null);

	useEffect(() => {
	
	}, []);

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
	// currentCase: state.all.currentCase,
});

const mdtp = (dispatch: Dispatch) => ({
    // getCase: payload => dispatch.all.getCase(payload),
	// getSubscribtions: () => dispatch.all.getSubscribtions(),
	// renameCase: payload => dispatch.all.renameCase(payload),
});

export default connect(mstp, mdtp)(ScannerScreen);
