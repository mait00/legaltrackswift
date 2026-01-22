//@ts-nocheck
import { createModel } from '@rematch/core';
import { API, StorageHelper } from './../../services';
import { ErrorsHelper } from './../../helpers';
import { Dispatch } from 'store';
import type { RootModel } from './../models';

type CategoryState = {
	categories: [
		{
			id: 0,
			name: 'Все',
		},
		{
			id: -1,
			name: 'Избранное',
		}
	],
	selectedCategory: [0],
};

const categories = createModel<RootModel>()({
	state: {
		categories: [
			{
				id: 0,
				name: 'Все',
			},
			{
				id: -1,
				name: 'Избранное',
			}
		],
		selectedCategory: [0],
	} as CategoryState, 
	reducers: {
		setSelectedCategory: (state, payload: boolean) => ({
			...state,
			selectedCategory: payload,
		}),
		setCategories: (state, payload: object) => ({
			...state,
			categories: payload,
		}),
	},
	effects: (dispatch) => {
		return {
			async getCategories(): Promise<any> {
				const response = await API.common.getCategories()
				console.warn('getCategories -> response', response);
				let array = [];
				array.push({
					id: 0,
					name: 'Все',
				});
				array.push({
					id: -1,
					name: 'Избранное',
				});
				array = array.concat(response.data.categories);
				dispatch.categories.setCategories(array);
			},
		}
	},
});

export default categories;