import React, { useEffect } from 'react';
import {Image, Alert, TextInput, View, Text, TouchableOpacity, Dimensions, FlatList} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from '../../utilities/Common';
import { colors } from '../../styles';
import {APP_NAME} from './../../constants';
import MultiSelect from 'react-native-multiple-select';

const MultiselectView = ({data, style, title, isCourt, selected, onSave}) => {

	const [selectedItems, setSelectedItems] = React.useState([]);
	const [courtsView, setcourtsView] = React.useState(null);
	const [items, setItems] = React.useState([]);
	const [tagView, setTagView] = React.useState(null);
	const multiSelect1 = React.useRef(null);

	useEffect(() => {
		// console.warn('data ' + title + ': ', data);
		setTagView(multiSelect1.current ? multiSelect1.current.getSelectedItemsExt(selectedItems) : null);
		setItems(data);
	}, [data]);

	useEffect(() => {
		setTagView(multiSelect1.current ? multiSelect1.current.getSelectedItemsExt(selected) : null);
		setSelectedItems(selected);
	}, [selected]);

	useEffect(() => {
		setTagView(multiSelect1.current ? multiSelect1.current.getSelectedItemsExt(selectedItems) : null);
	}, [selectedItems]);

	const onSelectedItemsChange = obj => {
		setSelectedItems(obj);
		if (onSave) {
			onSave(obj);
		}
	}

    return (
		<View style={[{
			width: Common.getLengthByIPhone7(0),
			alignItems: 'center',
		}, style]}>
			<MultiSelect
				styleMainWrapper={{
					marginTop: Common.getLengthByIPhone7(20),
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
					borderBottomWidth: 0,
					borderRadius: Common.getLengthByIPhone7(12),
					shadowColor: "#000",
					shadowOffset: {
						width: 0,
						height: 2,
					},
					shadowOpacity: 0.08,
					shadowRadius: 7.00,
					elevation: 1,
				}}
				styleInputGroup={{
					height: Common.getLengthByIPhone7(44),
				}}
				styleTextDropdown={{
					height: Common.getLengthByIPhone7(44),
					justifyContent: 'center',
					paddingLeft: Common.getLengthByIPhone7(18),
					paddingTop: Common.getLengthByIPhone7(15),
				}}
				styleTextDropdownSelected={{
					height: Common.getLengthByIPhone7(44),
					justifyContent: 'center',
					alignItems: 'center',
					paddingLeft: Common.getLengthByIPhone7(18),
					paddingTop: Common.getLengthByIPhone7(15),
				}}
				styleDropdownMenuSubsection={{
					paddingTop: 0,
					paddingBottom: 0,
				}}
				downIcon={<Image source={require('./../../assets/ic-add.png')}
					style={{
						width: Common.getLengthByIPhone7(20),
						height: Common.getLengthByIPhone7(20),
						resizeMode: 'contain',
						// tintColor: 'red',
					}}
				/>}
				closeIcon={<Image source={require('./../../assets/ic-close.png')}
					style={{
						width: Common.getLengthByIPhone7(24),
						height: Common.getLengthByIPhone7(24),
						resizeMode: 'contain',
						marginRight: 20,
						// tintColor: 'red',
					}}
				/>}
				hideTags
				items={items}
				uniqueKey="id"
				ref={component => { multiSelect1.current = component }}
				onSelectedItemsChange={onSelectedItemsChange}
				selectedItems={selectedItems}
				selectText={title}
				hideSubmitButton={true}
				hideDropdown={true}
				searchInputPlaceholderText="Поиск..."
				onChangeInput={ (text)=> console.log(text)}
				altFontFamily={"SFProDisplay-Regular"}
				fontFamily={"SFProDisplay-Regular"}
				itemFontFamily={'SFProDisplay-Regular'}
				itemFontSize={Common.getLengthByIPhone7(14)}
				itemTextColor={'rgba(66, 67, 71, 0.3)'}
				tagRemoveIconColor={colors.ORANGE_COLOR}
				tagBorderColor={colors.MAIN_COLOR}
				tagTextColor={colors.MAIN_COLOR}
				tagContainerStyle={{
					borderWidth: 0,
					backgroundColor: '#F4F4F4',
					padding: Common.getLengthByIPhone7(6),
					borderRadius: Common.getLengthByIPhone7(6),
					maxWidth: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
					// minHeight: Common.getLengthByIPhone7(30),
				}}
				styleTextTag={{
					color: colors.TEXT_COLOR,
				}}
				selectedItemTextColor="#322661"
				selectedItemIconColor="#322661"
				displayKey={isCourt ? "text" : 'value'}
				searchInputStyle={{ color: '#CCC' }}
				submitButtonColor="#CCC"
				submitButtonText="Готово"
			/>
			<View style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			}}>
				{tagView}
			</View>
		</View>
	);
};

const mstp = (state: RootState) => ({
	menuMode: state.buttons.menuMode,
});

const mdtp = (dispatch: Dispatch) => ({
	getSubscribtions: () => dispatch.all.getSubscribtions(),
	newSubscription: payload => dispatch.all.newSubscription(payload),
	searchCompanies: payload => dispatch.all.searchCompanies(payload),
	setMenuMode: payload => dispatch.buttons.setMenuMode(payload),
});

export default connect(mstp, mdtp)(MultiselectView);