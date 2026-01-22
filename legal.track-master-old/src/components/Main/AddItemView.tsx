import React, { useEffect } from 'react';
import {Image, TextInput, View, Text, TouchableOpacity} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from '../../utilities/Common';
import { colors } from '../../styles';

const texts = {
	'-1': 'Введите номер дела или ссылку',
	'0': 'Введите номер дела',
	'1': 'Введите ссылку на дело',
	'2': 'Введите ИНН',
};

const AddItemView = ({buttonIndex, setButtonIndex}) => {

	const [search, setSearch] = React.useState('');

    return (
		<View style={{
			marginTop: Common.getLengthByIPhone7(16),
			paddingBottom: Common.getLengthByIPhone7(17),
			borderBottomColor: 'rgba(50, 38, 97, 0.3)',
			borderBottomWidth: 1,
		}}>
			<View style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				height: Common.getLengthByIPhone7(108),
				borderRadius: Common.getLengthByIPhone7(12),
				alignItems: 'flex-start',
				justifyContent: 'center',
				backgroundColor: colors.MAIN_COLOR,
				paddingLeft: Common.getLengthByIPhone7(12),
				paddingRight: Common.getLengthByIPhone7(12),
			}}>
				<Text style={{
					color: 'white',
					fontFamily: 'SFProText-Regular',
					fontWeight: '600',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(16),
					lineHeight: Common.getLengthByIPhone7(22),
				}}
				allowFontScaling={false}>
					{buttonIndex === 2 ? 'Добавить компанию' : 'Добавить дело'}
				</Text>
				<View style={{
					marginTop: Common.getLengthByIPhone7(7),
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(64),
					height: Common.getLengthByIPhone7(44),
					backgroundColor: 'white',
					borderRadius: Common.getLengthByIPhone7(14),
				}}>
					<TextInput
						style={{
							width: Common.getLengthByIPhone7(0) - (buttonIndex === 0 ? Common.getLengthByIPhone7(190) : Common.getLengthByIPhone7(160)),
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
						placeholder={texts[buttonIndex]}
						// placeholderTextColor={this.props.placeholderTextColor}
						autoCompleteType={'off'}
						// inputAccessoryViewID={this.props.inputAccessoryViewID}
						multiline={false}
						numberOfLines={1}
						returnKeyType={'search'}
						secureTextEntry={false}
						autoCapitalize={'none'}
						underlineColorAndroid={'transparent'}
						onSubmitEditing={() => {
							
						}}
						// ref={el => this.textInputRef = el}
						onFocus={() => {
							
						}}
						onBlur={() => {
							
						}}
						onChangeText={(text) => {
							setSearch(text);
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
						{buttonIndex === 0 ? (<TouchableOpacity style={{
							width: Common.getLengthByIPhone7(36),
							height: Common.getLengthByIPhone7(36),
							alignItems: 'center',
							justifyContent: 'center',
						}}>
							<Image source={require('./../../assets/ic-qrcode.png')}
								style={{
									width: Common.getLengthByIPhone7(30),
									height: Common.getLengthByIPhone7(30),
									resizeMode: 'contain',
								}}
							/>
						</TouchableOpacity>) : null}
						<TouchableOpacity style={{
							width: Common.getLengthByIPhone7(81),
							height: Common.getLengthByIPhone7(38),
							borderRadius: Common.getLengthByIPhone7(10),
							alignItems: 'center',
							justifyContent: 'center',
							backgroundColor: colors.ORANGE_COLOR,
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
								{buttonIndex === 2 ? 'Найти' : 'Добавить'}
							</Text>
						</TouchableOpacity>
					</View>
				</View>
			</View>
		</View>
	);
};

const mstp = (state: RootState) => ({
	buttonIndex: state.buttons.buttonIndex,
});

const mdtp = (dispatch: Dispatch) => ({
	setButtonIndex: payload => dispatch.buttons.setButtonIndex(payload),
});

export default connect(mstp, mdtp)(AddItemView);