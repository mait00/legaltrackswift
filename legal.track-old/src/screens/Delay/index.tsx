import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, StatusBar, View, ScrollView, TouchableOpacity, Text } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {colors} from './../../styles';
import PlaceholderView from '../../components/PlaceholderView';
import DelayView from '../../components/Delay/DelayView';
import LoadingView from '../../components/LoadingView';
import SearchView from '../../components/Delay/SearchView';

const DelayScreen = ({getDelay, userProfile, delayList, delayRawList, setDelayRawList, isRequestGoing}) => {

	const navigation = useNavigation();
	const [body, setBody] = React.useState(null);

	useEffect(() => {
		getDelay();
		setInterval(() => {
			getDelay();
		}, 10000*60);
	}, []);

	const renderAlert = () => {
		return (<View style={{
			width: Common.getLengthByIPhone7(0),
			flex: 1,
			alignItems: 'center',
			justifyContent: 'center',
		}}>
			<Text style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: '600',
				textAlign: 'center',
				fontSize: Common.getLengthByIPhone7(20),
			}}
			allowFontScaling={false}>
				Данная функция недоступна в бесплатном тарифе, оплатите тариф и используйте весь функционал приложения
			</Text>
			<TouchableOpacity style={{
				marginTop: Common.getLengthByIPhone7(20),
				width: Common.getLengthByIPhone7(150),
				height: Common.getLengthByIPhone7(40),
				borderRadius: Common.getLengthByIPhone7(10),
				alignItems: 'center',
				justifyContent: 'center',
				backgroundColor: colors.ORANGE_COLOR,
			}}
			onPress={() => {
				navigation.navigate('Tarifs');
			}}>
				<Text style={{
					color: 'white',
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: '600',
					textAlign: 'center',
					fontSize: Common.getLengthByIPhone7(16),
				}}
				allowFontScaling={false}>
					Тарифы
				</Text>
			</TouchableOpacity>
		</View>);
	}

	useEffect(() => {
		if (isRequestGoing) {
			// setBody(<LoadingView/>);
		} else {
			if (!userProfile.is_tarif_active) {
				setBody(renderAlert());
			} else {
				let rows = [];
	
				for (let i = 0; i < delayList.length; i++) {
					rows.push(<DelayView
						data={delayList[i]}
						index={i}
						action={() => {
	
						}}
					/>);
				}
				setBody(<View style={{
					width: Common.getLengthByIPhone7(0),
					flex: 1,
					alignItems: 'center',
					justifyContent: 'flex-start',
				}}>
					<SearchView/>
					<ScrollView style={{
						width: Common.getLengthByIPhone7(0),
						flex: 1,
					}}
					contentContainerStyle={{
						alignItems: 'center',
						justifyContent: 'flex-start',
					}}>
						{rows}
					</ScrollView>
				</View>);
			}
		}
	}, [delayList, isRequestGoing]);

	return (
        <View style={{
            flex: 1,
            backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'center',
        }}>
			{body}
		</View>
	);
};

const mstp = (state: RootState) => ({
	delayList: state.all.delayList,
	delayRawList: state.all.delayRawList,
	isRequestGoing: state.user.isRequestGoing,
	userProfile: state.user.userProfile,
});

const mdtp = (dispatch: Dispatch) => ({
    getDelay: () => dispatch.all.getDelay(),
	setDelayRawList: payload => dispatch.all.setDelayRawList(payload),
});

export default connect(mstp, mdtp)(DelayScreen);
