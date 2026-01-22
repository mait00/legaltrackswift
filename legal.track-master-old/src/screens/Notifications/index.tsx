import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, StatusBar, View, TouchableOpacity, ScrollView, Text } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {GRAY_LIGHT, MAIN_COLOR} from './../../styles/colors';
import PlaceholderView from '../../components/PlaceholderView';
import NotifyView from '../../components/Notifications/NotifyView';
import LoadingView from '../../components/LoadingView';

const NotificationsScreen = ({getNotifications, notificationList, isRequestGoing}) => {

	const navigation = useNavigation();
	const [body, setBody] = React.useState(null);

	useEffect(() => {
		getNotifications();
	}, []);

	useEffect(() => {
		if (isRequestGoing) {
			setBody(<LoadingView/>);
		} else {
			if (notificationList.length === 0) {
				setBody(<PlaceholderView
					icon={require('./../../assets/ic-placeholder-notify.png')}
					title={'Уведомлений нет'}
				/>);
			} else {
				let rows = [];
	
				for (let i = 0; i < notificationList.length; i++) {
					rows.push(<NotifyView
						data={notificationList[i]}
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
	}, [notificationList, isRequestGoing]);

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
	notificationList: state.all.notificationList,
	isRequestGoing: state.user.isRequestGoing,
});

const mdtp = (dispatch: Dispatch) => ({
    getNotifications: () => dispatch.all.getNotifications(),
});

export default connect(mstp, mdtp)(NotificationsScreen);
