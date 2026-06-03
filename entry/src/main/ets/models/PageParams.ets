// models/PageParams.ets

export interface UriParam {
  uri: string;
}

export interface CategoryParam {
  category: string;
}

export interface IdParam {
  id: number;
}

export interface ExportParam {
  items: string;
  background: string;
}

export interface CollectionDetailParam {
  collectionId: number;
  collectionName: string;
  collectionColor: string;
}
