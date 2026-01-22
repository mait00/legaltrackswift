import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, StatusBar, View, TouchableOpacity, FlatList, Text } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { StackNavigationProp } from '@react-navigation/stack';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {GRAY_LIGHT, MAIN_COLOR} from './../../styles/colors';
import { parseSync } from '@babel/core';
import ButtonView from '../../components/Main/ButtonView';
import AddItemView from '../../components/Main/AddItemView';
import CaseView from '../../components/Main/CaseView';
import SouCaseView from '../../components/Main/SouCaseView';
import CompanyView from '../../components/Main/CompanyView';

const MainScreen = ({getSubscribtions, buttonIndex, allSubscriptions, casesList, companiesList, keywordsList}) => {

	const navigation = useNavigation();
	const [rows, setRows] = React.useState([]);

	useEffect(() => {
		getSubscribtions();
	}, []);

	useEffect(() => {
		if (buttonIndex === -1) {
			setRows(casesList);
		} else if (buttonIndex === 0) {
			let array = [];
			for (let i = 0; i < casesList.length; i++) {
				if (casesList[i].is_sou == null || casesList[i].is_sou == false) {
					array.push(casesList[i]);
				}
			}
			console.warn('array: ', array);
			setRows(array);
		} else if (buttonIndex === 1) {
			let array = [];
			for (let i = 0; i < casesList.length; i++) {
				if (casesList[i].is_sou) {
					array.push(casesList[i]);
				}
			}
			console.warn('array: ', array);
			setRows(array);
		} else {
			console.warn('array: ', companiesList);
			setRows(companiesList);
		}
	}, [allSubscriptions, casesList, companiesList, keywordsList, buttonIndex]);

	const renderRow = (item: object, index: number) => {
		
		// return null;
		if (buttonIndex === 2) {
			return (<CompanyView
				data={item}
				index={index}
				action={() => {
	
				}}
			/>);
		} else {
			if (item.is_sou) {
				return (<SouCaseView
					data={item}
					index={index}
					action={() => {
		
					}}
				/>);
			} else {
				return (<CaseView
					data={item}
					index={index}
					action={() => {
		
					}}
				/>);
			}
		}
    }

	return (
        <View style={{
            flex: 1,
            backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'center',
        }}>
			<ButtonView/>
			<AddItemView/>
			<FlatList
                style={{
                    flex: 1,
                    backgroundColor: 'transparent',
                    width: Common.getLengthByIPhone7(0),
                    // marginBottom: 60,
                    // marginTop: Common.getLengthByIPhone7(10),
                }}
                contentContainerStyle={{
                    alignItems: 'center',
                    justifyContent: 'flex-start',
                }}
                bounces={true}
                removeClippedSubviews={false}
                scrollEventThrottle={16}
                data={rows}
                extraData={rows}
                keyExtractor={(item, index) => index.toString()}
                renderItem={({item, index}) => renderRow(item, index)}
            />
		</View>
	);
};

const mstp = (state: RootState) => ({
	allSubscriptions: state.all.allSubscriptions,
	casesList: state.all.casesList,
	companiesList: state.all.companiesList,
	keywordsList: state.all.keywordsList,
	buttonIndex: state.buttons.buttonIndex,
});

const mdtp = (dispatch: Dispatch) => ({
    getSubscribtions: () => dispatch.all.getSubscribtions(),
});

export default connect(mstp, mdtp)(MainScreen);
