import React, { useEffect } from 'react';
import {Image, Alert, TextInput, View, Text, TouchableOpacity, Dimensions, FlatList} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from '../../utilities/Common';
import { colors } from '../../styles';
import {APP_NAME} from './../../constants';

const SearchView = ({searchDelays, setDelayRawList, delayRawList, delayList}) => {

	const [search, setSearch] = React.useState('');

	useEffect(() => {
		// nextClick();
	}, [search]);

	const nextClick = () => {
		if (search.length === 0) {
			Alert.alert(APP_NAME, 'Введите поисковую строку!');
			return;
		}

		searchDelays(search)
		.then(data => {
			setDelayRawList(data);
		})
		.catch(err => {
			Alert.alert(APP_NAME, err);
		});
	}

    return (
		<View style={{
			// marginTop: Common.getLengthByIPhone7(16),
			paddingBottom: Common.getLengthByIPhone7(17),
			// borderBottomColor: 'rgba(50, 38, 97, 0.3)',
			// borderBottomWidth: 1,
			// overflow: 'visible',
			// zIndex: 1000,
		}}>
			<View style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				// height: Common.getLengthByIPhone7(108),
				borderRadius: Common.getLengthByIPhone7(12),
				alignItems: 'flex-start',
				justifyContent: 'center',
				backgroundColor: colors.MAIN_COLOR,
				// paddingLeft: Common.getLengthByIPhone7(12),
				// paddingRight: Common.getLengthByIPhone7(12),
				padding: Common.getLengthByIPhone7(12),
			}}>
				<View style={{
					// marginTop: Common.getLengthByIPhone7(7),
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(64),
					height: Common.getLengthByIPhone7(44),
					backgroundColor: 'white',
					borderRadius: Common.getLengthByIPhone7(14),
				}}>
					<TextInput
						style={{
							width: Common.getLengthByIPhone7(220),
							height: Common.getLengthByIPhone7(44),
							borderRadius: Common.getLengthByIPhone7(14),
							backgroundColor: 'white',
							paddingLeft: Common.getLengthByIPhone7(10),
						}}
						clearButtonMode={'while-editing'}
						allowFontScaling={false}
						contextMenuHidden={false}
						spellCheck={true}
						autoCorrect={false}
						placeholder={'Введите номер дела'}
						placeholderTextColor={'rgba(50, 38, 97, 0.6)'}
						autoCompleteType={'off'}
						// inputAccessoryViewID={this.props.inputAccessoryViewID}
						multiline={false}
						numberOfLines={1}
						returnKeyType={'search'}
						secureTextEntry={false}
						autoCapitalize={'none'}
						underlineColorAndroid={'transparent'}
						onSubmitEditing={() => {
							nextClick();
						}}
						// ref={el => this.textInputRef = el}
						onFocus={() => {
							
						}}
						onBlur={() => {
							
						}}
						onChangeText={(text) => {
							setSearch(text);
							if (text.length === 0) {
								setDelayRawList(delayRawList);
							}
						}}
						value={search}
					/>
					<View style={{
						height: Common.getLengthByIPhone7(44),
						position: 'absolute',
						top: 0,
						right: 0,
						flexDirection: 'row',
						alignItems: 'center',
						justifyContent: 'flex-end',
						paddingRight: Common.getLengthByIPhone7(4),
					}}>
						<TouchableOpacity style={{
							width: Common.getLengthByIPhone7(81),
							height: Common.getLengthByIPhone7(38),
							borderRadius: Common.getLengthByIPhone7(10),
							alignItems: 'center',
							justifyContent: 'center',
							backgroundColor: colors.ORANGE_COLOR,
						}}
						onPress={() => {
							nextClick();
						}}>
							<Text style={{
								color: 'white',
								fontFamily: 'SFProText-Regular',
								fontWeight: 'bold',
								textAlign: 'left',
								fontSize: Common.getLengthByIPhone7(12),
								lineHeight: Common.getLengthByIPhone7(22),
							}}
							allowFontScaling={false}>
								Найти
							</Text>
						</TouchableOpacity>
					</View>
				</View>
			</View>
		</View>
	);
};

const mstp = (state: RootState) => ({
	delayList: state.all.delayList,
	delayRawList: state.all.delayRawList,
});

const mdtp = (dispatch: Dispatch) => ({
	searchDelays: payload => dispatch.all.searchDelays(payload),
	setDelayRawList: payload => dispatch.all.setDelayRawList(payload),
});

export default connect(mstp, mdtp)(SearchView);