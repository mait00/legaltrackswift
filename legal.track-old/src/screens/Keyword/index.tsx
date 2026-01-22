import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, Image, View, TouchableOpacity, Alert, FlatList, Text } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {colors} from './../../styles';
import MultiselectView from '../../components/Keyword/MultiselectView';
import { LogBox } from 'react-native';
import {APP_NAME} from './../../constants';
import Dialog from "react-native-dialog";

const rows = [
	{id: 1},
	{id: 2},
];

const KeywordScreen = ({route, getKeyword, getSubscribtions, editKeyword, instancesList, courtList, categoriesList, getCategoriesCases, getInstances, getCourts}) => {

	const navigation = useNavigation();
	const [body, setBody] = React.useState(null);
	const [data, setData] = React.useState(null);
	const [visible, setVisible] = React.useState(false);
	const [keywordname, setKeywordName] = React.useState('');

	useEffect(() => {
		
		setBody(null);
		getKeyword(route.params.data.id)
		.then(data => {
			console.warn('data: ', data);
			setData(data);
			setKeywordName(data.value);
		})
		.catch(err => {

		});

		getCategoriesCases()
		.then(data => {
			
		})
		.catch(err => {

		});

		getCourts()
		.then(data => {
			
		})
		.catch(err => {

		});

		getInstances()
		.then(data => {
			
		})
		.catch(err => {

		});

		
	}, []);

	useEffect(() => {
		renderBody();
	}, [data, instancesList, courtList, categoriesList]);

	const renderRow = (item: object, index: number) => {
		if (item.id === 1) {
			return (<View style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				borderRadius: Common.getLengthByIPhone7(12),
				backgroundColor: colors.MAIN_COLOR,
				alignItems: 'center',
			}}>
				<View style={{
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(72),
					paddingTop: Common.getLengthByIPhone7(7),
					paddingBottom: Common.getLengthByIPhone7(7),
					flexDirection: 'row',
					alignItems: 'center',
					justifyContent: 'space-between',
					borderBottomColor: 'white',
					borderBottomWidth: 1,
				}}>
					<Text style={{
						maxWidth: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(120),
						color: 'white',
						fontFamily: 'SFProDisplay-Regular',
						fontWeight: '600',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(20),
					}}
					allowFontScaling={false}>
						{data.value}
					</Text>
					<TouchableOpacity style={{

					}}
					onPress={() => {
						setVisible(true);
					}}>
						<Image source={require('./../../assets/ic-button-rename.png')}
							style={{
								width: Common.getLengthByIPhone7(36),
								height: Common.getLengthByIPhone7(36),
								tintColor: colors.ORANGE_COLOR,
								resizeMode: 'contain',
							}}
						/>
					</TouchableOpacity>
				</View>
				<View style={{
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(72),
					paddingTop: Common.getLengthByIPhone7(14),
					paddingBottom: Common.getLengthByIPhone7(19),
					flexDirection: 'row',
					alignItems: 'center',
					justifyContent: 'flex-start',
				}}>
					<Text style={{
						color: 'rgba(255, 255, 255, 0.39)',
						fontFamily: 'SFProDisplay-Regular',
						fontWeight: '600',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(12),
					}}
					allowFontScaling={false}>
						Событий  <Text style={{
							color: 'white',
							fontFamily: 'SFProDisplay-Regular',
							fontWeight: 'normal',
							textAlign: 'left',
							fontSize: Common.getLengthByIPhone7(12),
						}}
						allowFontScaling={false}>
							{data.total_cases}
						</Text>
					</Text>
				</View>
			</View>);
		} else {
			return (<View style={{
				width: Common.getLengthByIPhone7(0),
				flex: 1,
				alignItems: 'center',
				justifyContent: 'flex-start',
			}}>
				<MultiselectView
					style={{

					}}
					title={'Суд'}
					isCourt={true}
					data={courtList}
					selected={data.courts}
					onSave={selectedItems => {
						let body = {
							id: data.id,
							value: data.value,
							courts: selectedItems,
							categories: data.categories,
							instances: data.instances,
						};
						editKeyword(body)
						.then(() => {
							getKeyword(route.params.data.id)
							.then(data => {
								console.warn('data: ', data);
								setData(data);
							})
							.catch(err => {

							});
							getSubscribtions();
						})
						.catch(err => {
							Alert.alert(APP_NAME, err);
						});
					}}
				/>
				<MultiselectView
					style={{
						
					}}
					title={'Категория дела'}
					data={categoriesList}
					selected={data.categories}
					onSave={selectedItems => {
						let body = {
							id: data.id,
							value: data.value,
							courts: data.courts,
							categories: selectedItems,
							instances: data.instances,
						};
						editKeyword(body)
						.then(() => {
							getKeyword(route.params.data.id)
							.then(data => {
								console.warn('data: ', data);
								setData(data);
							})
							.catch(err => {

							});
							getSubscribtions();
						})
						.catch(err => {
							Alert.alert(APP_NAME, err);
						});
					}}
				/>
				<MultiselectView
					style={{
						
					}}
					title={'Инстанция'}
					data={instancesList}
					selected={data.instances}
					onSave={selectedItems => {
						let body = {
							id: data.id,
							value: data.value,
							courts: data.courts,
							categories: data.categories,
							instances: selectedItems,
						};
						editKeyword(body)
						.then(() => {
							getKeyword(route.params.data.id)
							.then(data => {
								console.warn('data: ', data);
								setData(data);
							})
							.catch(err => {

							});
							getSubscribtions();
						})
						.catch(err => {
							Alert.alert(APP_NAME, err);
						});
					}}
				/>
			</View>);
		}
	}

	const renderBody = () => {
		console.warn(data);
		if (!data) {
			return null;
		}
		setBody(<FlatList
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
		/>);
	}

	return (
        <View style={{
            flex: 1,
            backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'center',
        }}>
			{body}
			<Dialog.Container visible={visible}>
				<Dialog.Title>Переименовать ключевое слово</Dialog.Title>
				<Dialog.Input value={keywordname} onChangeText={text => setKeywordName(text)} />
				<Dialog.Button label="Отмена" onPress={() => {
					setVisible(false);
				}} />
				<Dialog.Button label="Сохранить" onPress={() => {
					if (keywordname.length) {
						let body = {
							id: data.id,
							value: keywordname,
							courts: data.courts,
							categories: data.categories,
							instances: data.instances,
						};
						setVisible(false);
						editKeyword(body)
						.then(() => {
							getKeyword(route.params.data.id)
							.then(data => {
								console.warn('data: ', data);
								setData(data);
							})
							.catch(err => {

							});
							getSubscribtions();
						})
						.catch(err => {
							Alert.alert(APP_NAME, err);
						});
					} else {
						Alert.alert(APP_NAME, 'Укажите название!');
					}
				}} />
			</Dialog.Container>
		</View>
	);
};

const mstp = (state: RootState) => ({
	courtList: state.all.courtList,
	categoriesList: state.all.categoriesList,
	instancesList: state.all.instancesList,
});

const mdtp = (dispatch: Dispatch) => ({
    getKeyword: payload => dispatch.all.getKeyword(payload),
	getInstances: () => dispatch.all.getInstances(),
	getCourts: () => dispatch.all.getCourts(),
	getCategoriesCases: () => dispatch.all.getCategoriesCases(),
	getSubscribtions: () => dispatch.all.getSubscribtions(),
	editKeyword: payload => dispatch.all.editKeyword(payload),
});

export default connect(mstp, mdtp)(KeywordScreen);
