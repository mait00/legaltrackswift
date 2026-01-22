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

const CaseNotifyScreen = ({route, mutePushCase, muteSidesCase, getSubscribtions}) => {

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
			if (data.is_bankrot) {
				let array = [];
				if (data.sides.Plaintiffs && data.sides.Plaintiffs.length) {
					for (let i = 0; i < data.sides.Plaintiffs.length; i++) {
						array.push(data.sides.Plaintiffs[i].Id);
					}
				}
		
				if (data.sides.Defendants && data.sides.Defendants.length) {
					for (let i = 0; i < data.sides.Defendants.length; i++) {
						array.push(data.sides.Defendants[i].Id);
					}
				}
		
				if (data.sides.Third && data.sides.Third.length) {
					for (let i = 0; i < data.sides.Third.length; i++) {
						array.push(data.sides.Third[i].Id);
					}
				}
				
				setAllSide(array);
				setMutedSide(data.muted_side);
				setBody(renderBankrot())
			} else {
				setBody(renderNonBankrot())
			}
		}
	}, [data]);

	useEffect(() => {
		if (data) {
			console.warn(data.muted_all);
			if (data.is_bankrot) {
				// setMutedSide(data.muted_side);
				setBody(renderBankrot())
			} else {
				setBody(renderNonBankrot())
			}
		}
	}, [muted]);

	useEffect(() => {
		console.warn('mutedSide: ', mutedSide);
		if (data) {
			if (data.is_bankrot) {
				setBody(renderBankrot())
			} else {
				setBody(renderNonBankrot())
			}
		}
	}, [mutedSide]);

	const renderSides = (title, sides, selected) => {
		console.warn(title, selected);

		let array = [];
		for (let i = 0; i < sides.length; i++) {
			array.push({
				id: sides[i].Id,
				value: sides[i].Name,
			});
		}
		return (<MultiselectView
			style={{

			}}
			title={title}
			data={array}
			selected={selected}
			onSave={selectedItems => {

				let array = JSON.parse(JSON.stringify(mutedSide));

				for (let y = 0; y < selected.length; y++) {
					for(let i = 0; i < array.length; i++) {
						if ( array[i] === selected[y]) {
							array.splice(i, 1);
							break;
						}
					}
				}
				console.warn('before: ', array.length);
				array = array.concat(selectedItems);
				console.warn('after: ', array.length);

				setMutedSide(array);
				if (allSide.length !== array.length) {
					setMuted(false);
				} else {
					setMuted(true);
				}
				muteSidesCase({id: data.id, muted_list: array})
				.then(() => {
					getSubscribtions();
					route.params.action();
				})
				.catch(err => {

				});
			}}
		/>);
	}

	const renderRow = (item: object, index: number) => {
		if (item.id == 1) {
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
					{data['case-number']}
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
						Присылать все уведомления
					</Text>
					<Switch
						onValueChange={value => {
							console.warn(value);
							
							let select = [];
							if (value) {
								select = [];
								setMutedSide(allSide);
							} else {
								select = allSide;
								setMutedSide([]);
							}
							console.warn('select before: ', select);
							
							muteSidesCase({id: data.id, muted_list: select})
							.then(() => {
								// let dd = JSON.parse(JSON.stringify(data));
								// dd.muted_all = !value;
								// setData(dd);
								route.params.action();
								getSubscribtions();
							})
							.catch(err => {

							});

							setMuted(value);
						}}
						value={muted}
					/>
				</View>
			</View>);
		} else {
			let rows = [];
			
			if (data.sides.Plaintiffs && data.sides.Plaintiffs.length) {
				let select = [];
				for (let i = 0; i < data.sides.Plaintiffs.length; i++) {
					if (mutedSide.includes(data.sides.Plaintiffs[i].Id)) {
						select.push(data.sides.Plaintiffs[i].Id);
					}
				}
				rows.push(renderSides('Истцы', data.sides.Plaintiffs, select));
			}

			if (data.sides.Defendants && data.sides.Defendants.length) {
				let select = [];
				for (let i = 0; i < data.sides.Defendants.length; i++) {
					if (mutedSide.includes(data.sides.Defendants[i].Id)) {
						select.push(data.sides.Defendants[i].Id);
					}
				}
				rows.push(renderSides('Ответчики', data.sides.Defendants, select));
			}

			if (data.sides.Third && data.sides.Third.length) {
				let select = [];
				for (let i = 0; i < data.sides.Third.length; i++) {
					if (mutedSide.includes(data.sides.Third[i].Id)) {
						select.push(data.sides.Third[i].Id);
					}
				}
				rows.push(renderSides('Третьи стороны', data.sides.Third, select));
			}
			return (<View style={{
				marginTop: Common.getLengthByIPhone7(10),
				width: Common.getLengthByIPhone7(0),
				// paddingLeft: Common.getLengthByIPhone7(20),
				// paddingRight: Common.getLengthByIPhone7(20),
			}}>
				{rows}
			</View>);
		}
	}

	const renderBankrot = () => {
		// console.warn(data);
		let rows = [];

		if (data.sides.Plaintiffs && data.sides.Plaintiffs.length) {
			rows.push(renderSides('Истцы', data.sides.Plaintiffs));
		}

		if (data.sides.Defendants && data.sides.Defendants.length) {
			rows.push(renderSides('Ответчики', data.sides.Defendants));
		}

		if (data.sides.Third && data.sides.Third.length) {
			rows.push(renderSides('Третьи стороны', data.sides.Third));
		}

		return (<FlatList
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
			data={rowsItem}
			extraData={rowsItem}
			keyExtractor={(item, index) => index.toString()}
			renderItem={({item, index}) => renderRow(item, index)}
		/>);
	}

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
				{data['case-number']}
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
	// getCurrCase: state.all.getCurrCase,
});

const mdtp = (dispatch: Dispatch) => ({
    mutePushCase: payload => dispatch.all.mutePushCase(payload),
	getSubscribtions: () => dispatch.all.getSubscribtions(),
	muteSidesCase: payload => dispatch.all.muteSidesCase(payload),
});

export default connect(mstp, mdtp)(CaseNotifyScreen);
