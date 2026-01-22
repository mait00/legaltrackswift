import { Models } from "@rematch/core";
import buttons from "./buttons";
import user from "./user";
import all from "./all";

export interface RootModel extends Models<RootModel> {
	buttons: typeof buttons;
	user: typeof user;
	all: typeof all;	
}

export const models: RootModel = { buttons, user, all };