//@ts-nocheck
import { createModel } from '@rematch/core';
import { API, StorageHelper } from './../../services';
import { ErrorsHelper } from './../../helpers';
import { Dispatch } from 'store';
import type { RootModel } from './../models';
import { getDistance } from 'geolib';

type LocationState = {
	coords: object,
};

const location = createModel<RootModel>()({
	state: {
		coords: null,
	} as LocationState, 
	reducers: {
		setCoords: (state, payload: object) => ({
			...state,
			coords: payload,
		}),
	},
	effects: (dispatch: Dispatch) => {
		return {
			getDistanceToPoint: (start, end) => {
				console.warn('start: ', start, ' end: ', end);
				if (start && end) {
					return getDistance(start, end);
				} else {
					return 0;
				}
			},
		}
	},
});

export default location;