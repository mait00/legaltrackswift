import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, StatusBar, View, ScrollView, FlatList, Text } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {GRAY_LIGHT, MAIN_COLOR} from './../../styles/colors';
import PlaceholderView from '../../components/PlaceholderView';
import DelayView from '../../components/Delay/DelayView';
import LoadingView from '../../components/LoadingView';

const DelayScreen = ({getDelay, delayList, isRequestGoing}) => {

	const navigation = useNavigation();
	const [body, setBody] = React.useState(null);

	useEffect(() => {
		getDelay();
		setInterval(() => {
			getDelay();
		}, 10000*60);
	}, []);

	useEffect(() => {
		if (isRequestGoing) {
			setBody(<LoadingView/>);
		} else {
			if (delayList.length === 0) {
				setBody(<PlaceholderView
					icon={require('./../../assets/ic-placeholder-delay.png')}
					title={'Заседаний нет'}
					subtitle={'Мы не нашли судебных заседаний в пределах 3х дней'}
				/>);
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
				setBody(<ScrollView style={{
					width: Common.getLengthByIPhone7(0),
					flex: 1,
				}}
				contentContainerStyle={{
					alignItems: 'center',
					justifyContent: 'flex-start',
				}}>
					{rows}
				</ScrollView>);
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
	isRequestGoing: state.user.isRequestGoing,
});

const mdtp = (dispatch: Dispatch) => ({
    getDelay: () => dispatch.all.getDelay(),
});

export default connect(mstp, mdtp)(DelayScreen);
