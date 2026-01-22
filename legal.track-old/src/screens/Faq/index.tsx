import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, StatusBar, View, TouchableOpacity, FlatList, Text } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {colors} from './../../styles';
import ItemView from '../../components/Faq/ItemView';

const FaqScreen = ({faqList, getFaq}) => {

	const navigation = useNavigation();

	useEffect(() => {
		getFaq();
	}, []);

	const renderRow = (item: object, index: number) => {
		return (<ItemView
			data={item}
			index={index}
		/>);
    }

	return (
        <View style={{
            flex: 1,
            backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'center',
        }}>
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
				data={faqList}
				extraData={faqList}
				keyExtractor={(item, index) => index.toString()}
				renderItem={({item, index}) => renderRow(item, index)}
			/>
		</View>
	);
};

const mstp = (state: RootState) => ({
	faqList: state.all.faqList,
});

const mdtp = (dispatch: Dispatch) => ({
    getFaq: () => dispatch.all.getFaq(),
});

export default connect(mstp, mdtp)(FaqScreen);
