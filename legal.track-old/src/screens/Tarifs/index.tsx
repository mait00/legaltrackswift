import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, ScrollView, View, TouchableOpacity, Image, Text } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {colors} from './../../styles';
import TarifsView from '../../components/Tarifs/TarifsView';

const TarifsScreen = ({}) => {

	const navigation = useNavigation();

	return (
        <View style={{
            flex: 1,
            backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'center',
        }}>
			<TarifsView />
		</View>
	);
};

const mstp = (state: RootState) => ({
	
});

const mdtp = (dispatch: Dispatch) => ({
    
});

export default connect(mstp, mdtp)(TarifsScreen);
