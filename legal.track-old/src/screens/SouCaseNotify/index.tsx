import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, StatusBar, View, TouchableOpacity, FlatList, Text, Switch, ScrollView } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {colors} from './../../styles';
import MultiselectView from '../../components/Keyword/MultiselectView';

const rowsItem = [
	{id: 1},
	{id: 2},
];

const SouCaseNotifyScreen = ({route, mutePushCase, getSubscribtions}) => {

	const navigation = useNavigation();
	const [data, setData] = React.useState(null);
	const [body, setBody] = React.useState(null);
	const [muted, setMuted] = React.useState(false);
	const [mutedAll, setMutedAll] = React.useState(false);
	const [mutedSide, setMutedSide] = React.useState([]);
	const [allSide, setAllSide] = React.useState([]);

	useEffect(() => {
		setData(route.params.data);
	}, []);

	useEffect(() => {
		if (data) {
			console.warn(data.muted_side);
			setMuted(data.muted_all == false ? true : false);
			console.warn(data);
			setBody(renderNonBankrot())
		}
	}, [data]);

	useEffect(() => {
		if (data) {
			console.warn(data.muted_all);
			setBody(renderNonBankrot())
		}
	}, [muted]);

	useEffect(() => {
		console.warn('mutedSide: ', mutedSide);
		if (data) {
			setBody(renderNonBankrot())
		}
	}, [mutedSide]);

	const renderNonBankrot = () => {
		console.warn(data);
		return (<View style={{
			marginTop: Common.getLengthByIPhone7(10),
			width: Common.getLengthByIPhone7(0),
			// paddingLeft: Common.getLengthByIPhone7(20),
			// paddingRight: Common.getLengthByIPhone7(20),
		}}>
			<Text style={{
				// maxWidth: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(120),
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: '600',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(20),
				lineHeight: Common.getLengthByIPhone7(24),
				marginLeft: Common.getLengthByIPhone7(20),
				marginRight: Common.getLengthByIPhone7(20),
			}}
			allowFontScaling={false}>
				{data.name ? data.name : data.value}
			</Text>
			<View style={{
				backgroundColor: 'rgba(50, 38, 97, 0.05)',
				width: Common.getLengthByIPhone7(0),
				height: Common.getLengthByIPhone7(44),
				flexDirection: 'row',
				alignItems: 'center',
				justifyContent: 'space-between',
				paddingLeft: Common.getLengthByIPhone7(20),
				paddingRight: Common.getLengthByIPhone7(20),
				marginTop: Common.getLengthByIPhone7(14),
			}}>
				<Text style={{
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProText-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(17),
					lineHeight: Common.getLengthByIPhone7(22),
				}}
				allowFontScaling={false}>
					Присылать уведомления
				</Text>
				<Switch
					onValueChange={value => {
						console.warn(value);
						setMuted(value);
						mutePushCase({id: data.id, mute_all: !value})
						.then(() => {
							let dd = JSON.parse(JSON.stringify(data));
							dd.muted_all = !value;
							setData(dd);
							route.params.action();
							getSubscribtions();
						})
						.catch(err => {

						});
					}}
					value={muted}
				/>
			</View>
		</View>);
	}

	return (
        <View style={{
            flex: 1,
            backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'flex-start',
        }}>
			{body}
		</View>
	);
};

const mstp = (state: RootState) => ({
	// bills: state.bills.bills,
});

const mdtp = (dispatch: Dispatch) => ({
    mutePushCase: payload => dispatch.all.mutePushCase(payload),
	getSubscribtions: () => dispatch.all.getSubscribtions(),
});

export default connect(mstp, mdtp)(SouCaseNotifyScreen);
